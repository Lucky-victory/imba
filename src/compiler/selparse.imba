var selparser = require('../../vendor/css-selector-parser')
import {fonts,colors,variants,breakpoints,modifiers} from './theme.imba'

def addClass rule, name
	rule.classNames ||= []
	if rule.classNames.indexOf(name) == -1
		rule.classNames.push(name)
	return rule

def addPseudo rule, pseudo
	rule.pseudos ||= []
	if typeof pseudo == 'string'
		pseudo = {name: pseudo}

	rule.pseudos.push(pseudo)
	return rule

def getRootRule ruleset
	let rule = ruleset.rule
	if rule.tagName != 'html'
		rule = ruleset.rule = {type: 'rule',tagName:'html',classNames:[],rule: rule}
	return rule
	
def addRootClass ruleset, name
	let rule = ruleset.rule
	if rule.tagName != 'html'
		rule = ruleset.rule = {type: 'rule',tagName:'html',classNames:[],rule: rule}
	addClass(rule,name)
	return ruleset
	
	
def wrapRule rule, wrapper
	yes
	
def cloneRule rule
	JSON.parse(JSON.stringify(rule))
	
export def rewrite rule,ctx,scope = {}
	
	if rule.type == 'selectors'
		for sel in rule.selectors
			rewrite(sel,rule,scope)
			
	if rule.type == 'ruleSet'
		let root = rule
		rule.meta = {}
		rule.media = []

		let parts = []
		let curr = rule.rule
		while curr
			parts.push(curr)
			curr = curr.rule
		
		let rev = parts.slice(0).reverse!
		
		# hack
		for part,i in rev
			let up = rev[i + 1]
			let flags = part.classNames
			let mods = part.pseudos
			let name = part.tagName
			let op = part.nestingOperator
			
			if !flags and !name and !op and (mods and mods.every(do $1.special))
				# console.log 'send up to the parent',part,up,part == up
				if up
					up.pseudos = (up.pseudos or []).concat(mods)
					up.rule = part.rule
					parts.splice(parts.indexOf(part),1)
				# else
				# 	console.log 'cannot send further up!!!'
		
		let container = parts[0]

		for part,i in parts
			let prev = parts[i - 1]
			let next = parts[i + 1]
			let flags = part.classNames ||= []
			let mods = part.pseudos or []
			let name = part.tagName
			let op = part.nestingOperator
			
			if name and name[0] == '$'
				part.tagName = null
				addClass(part,name.slice(1))
				addClass(part,scope.localid)
				# flags.unshift(name.slice(1))
				# flags.unshift(scope.localid)
			elif name and name[0] == '%'
				
				part.tagName = null
				addClass(part,'mixin___'+name.slice(1))
				
			if scope.forceLocal
				addClass(part,scope.localid)
				# flags.unshift(scope.localid)
			
			let modTarget = part
			
			for mod in mods when mod.special
				
				let [m,pre,name,post] = (mod.name.match(/^(\$|\.+|is-|up-)?([^\~\+]*)([\~\+]*)$/) or [])

				if pre == '.' or pre == 'is-'
					# console.log 'class mod!!',mod
					addClass(modTarget,name)
					mod.remove = yes
				
				elif pre == '..' or pre == 'up-'
					prev ||= root.rule = {type: 'rule',classNames:[],rule:root.rule}
					addClass(modTarget = prev,name)
					mod.remove = yes
					
				if post == '~'
					# console.log 'after selector!!',mod,part
					modTarget

				if let alias = modifiers[mod.name]
					if alias.media
						rule.media.push(alias.media)
						mod.remove = yes
					if alias.ua
						# get or force-create html element
						addClass(getRootRule(rule),"ua-{alias.ua}")
						mod.remove = yes
					
					unless mod.remove
						Object.assign(mod,alias)

				elif mod.name == 'local'
					mod.remove = yes
					scope.hasLocalRules = yes
					flags.push(scope.localid) if scope.localid
				
				if modTarget != part and !mod.remove
					addPseudo(modTarget,mod)
					mod.remove = yes

				# if let m = mod.name.match(/^(in|is|up)-(.+)$/)
				# 	mod.remove = yes
				# 	if m[1] == 'is'
				# 		addClass(part,m[2])
				# 	elif m[1] == 'in' or m[1] == 'up'
				# 		unless prev
				# 			root.rule = {type: 'rule',classNames:[m[2]],rule:root.rule}
				# 		else
				# 			addClass(prev,m[2])

			part.pseudos = mods.filter do !$1.remove
		
		# console.log 'parts afte rewrite',parts
	return rule

export def render root, content
	let group = ['']
	let groups = [group]
	let rules = root.selectors or [root]

	for rule in rules
		let sel = selparser.render(rule)
		let media = rule.media.length ? "@media {rule.media.join(' and ')}" : ''
		if media != group[0]
			groups.push(group = [media])
		
		group.push(sel)
		
	let out = []
	
	for group in groups when group[1]
		let sel = group.slice(1).join(',') + ' {$CONTENT$}'
		if group[0]
			sel = group[0] + '{\n' + sel + '\n}'
		out.push(sel)
	
	return out.join('\n').replace(/\$CONTENT\$/g,content)

	# console.log selparser.render(out)

export def unwrap parent, subsel
	let pars = parent.split(',')
	let subs = subsel.split(',')
	
	let sels = []

	for sub in subs
		for par in pars
			let sel = sub
			if sel.indexOf('&') >= 0
				sel = sel.replace('&',par)
			else
				sel = par + ' ' + sel
			sels.push(sel)

	return sels.join(',')
	
export def parse str, options
	let sel = selparser.parse(str)
	let out = rewrite(sel,null,options)
	return out

export def test str, log = no
	var sel = selparser.parse(str)
	console.log 'parsed',str,sel
	var options = {localid: 'dvs342'}
	var out = rewrite(sel,null,options)
	let css = render(out)
	console.log css
	if log
		console.dir sel,{ depth: null }
	return css

# test '.one:hover .test:hocus.test > again'
# test '.test@in-base div.one @focus @in-active @in-other @md'
# test '$editor @focus'
# test 'div@odd @md,li@even @lg,li @md @not-lg'
# test '@media only screen and (max-width: 600px)',true
# test '.one .test@in-active'
# test '.one@focus,.two@in-disabled'