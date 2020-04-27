import {CustomEvent,Element} from '../dom'

const observers = global.WeakMap ? global.WeakMap.new : global.Map.new
const defaults = {threshold: [0]}
const rootTarget = {}

class IntersectEvent < CustomEvent
	
	get ratio
		detail.ratio
	
	get delta
		detail.delta
		
	def handle$mod state, args
		let obs = state.event.detail.observer
		return state.modifiers._observer == obs
	
	def in$mod state, args
		return state.event.delta > 0

	def out$mod state, args
		return state.event.delta < 0

def callback name, key
	return do |entries,observer|
		let map = observer.prevRatios ||= WeakMap.new
		
		for entry in entries
			let prev = map.get(entry.target) or 0
			let ratio = entry.intersectionRatio
			let detail = {entry: entry, ratio: ratio, from: prev, delta: (ratio - prev), observer: observer }
			let e = IntersectEvent.new(name, bubbles: false, detail: detail)
			map.set(entry.target,ratio)
			entry.target.dispatchEvent(e)
		return

def getIntersectionObserver opts = defaults
	let key = opts.threshold.join('-') + opts.rootMargin
	let target = opts.root or rootTarget
	let map = observers.get(target)
	map || observers.set(target,map = {})
	map[key] ||= IntersectionObserver.new(callback('intersect',key),opts)

Element.prototype.on$intersect = do(mods,context)
	let obs
	if mods.options
		let opts = {threshold: []}

		for arg in mods.options
			if arg isa Element
				opts.root = arg
			elif typeof arg == 'number'
				opts.threshold.push(arg)

		opts.threshold.push(0) if opts.threshold.length == 0
		obs = getIntersectionObserver(opts)
	else
		obs = getIntersectionObserver()

	mods._observer = obs
	obs.observe(this)