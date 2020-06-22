import {Event,Element} from '../dom'

Event.pointerdown = {
	handle: do(state,options)
		# only if touch
		let e = state.event
		let el = state.element
		let handler = state.handler
		return true if handler.type != 'touch'
		
		e.dx = e.dy = 0
		handler.x0 = e.x
		handler.y0 = e.y
		handler.pointerId = e.pointerId

		let canceller = do return false
		let selstart = document.onselectstart
		el.setPointerCapture(e.pointerId)

		el.addEventListener('pointermove',handler)
		el.addEventListener('pointerup',handler)
		document.onselectstart = canceller

		el.flags.add('_touch_')

		el.addEventListener('pointerup',&,once: true) do(e)
			el.releasePointerCapture(e.pointerId)
			el.removeEventListener('pointermove',handler)
			el.removeEventListener('pointerup',handler)
			handler.pointerId = null
			if handler.pointerFlag
				el.flags.remove(handler.pointerFlag)
			el.flags.remove('_touch_')
			document.onselectstart = selstart
		yes			
}

Event.pointermove = {
	handle: do(s,args)
		let h = s.handler
		let e = s.event
		let id = h.pointerId
		return false if id and e.pointerId != id
		if typeof h.x0 == 'number'
			e.dx = e.x - h.x0
			e.dy = e.y - h.y0
		return true
}
Event.pointerup = {
	handle: do(s,args)
		let h = s.handler
		let e = s.event
		let id = h.pointerId
		return false if id and e.pointerId != id
		if typeof h.x0 == 'number'
			e.dx = e.x - h.x0
			e.dy = e.y - h.y0
		return true
}


Element.prototype.on$touch = do(mods,context)
	return