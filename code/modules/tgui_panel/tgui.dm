/**
 * private
 *
 * Updates the status, and returns TRUE if status has changed.
 */
/datum/tgui/proc/process_status()
	var/prev_status = status
	status = src_object.ui_status(user, state)
	return prev_status != status

/**
 * private
 *
 * Callback for handling incoming tgui messages.
 */
/*
/datum/tgui/proc/on_message(type, list/payload, list/href_list)
	// Pass act type messages to ui_act
	if(type && copytext(type, 1, 5) == "act/")
		var/act_type = copytext(type, 5)

		var/id = href_list["packetId"]
		if(!isnull(id))
			id = text2num(id)

			var/total = text2num(href_list["totalPackets"])

			if(total > MAX_MESSAGE_CHUNKS)
				return

			if(id == 1)
				partial_packets = new /list(total)

			partial_packets[id] = href_list["packet"]

			if(id != total)
				return

			var/assembled_payload = ""
			for(var/packet in partial_packets)
				assembled_payload += packet

			payload = json_decode(assembled_payload)
			partial_packets = null

		log_tgui(user, "Action: [act_type] [href_list["payload"]]",
			window = window,
			src_object = src_object)
		process_status()
		//DEFAULT_QUEUE_OR_CALL_VERB(VERB_CALLBACK(src, PROC_REF(on_act_message), act_type, payload, state))
		on_act_message(act_type, payload, state)
		return FALSE
	switch(type)
		if("ready")
			// Send a full update when the user manually refreshes the UI
			if(initialized)
				send_full_update()
			initialized = TRUE
		if("ping/reply")
			initialized = TRUE
		if("suspend")
			close(can_be_suspended = TRUE)
		if("close")
			close(can_be_suspended = FALSE)
		if("log")
			if(href_list["fatal"])
				close(can_be_suspended = FALSE)
		if("setSharedState")
			if(status != UI_INTERACTIVE)
				return
			LAZYINITLIST(src_object.tgui_shared_states)
			src_object.tgui_shared_states[href_list["key"]] = href_list["value"]
			SStgui.update_uis(src_object)
*/
/// Wrapper for behavior to potentially wait until the next tick if the server is overloaded
/datum/tgui/proc/on_act_message(act_type, payload, state)
	if(QDELETED(src) || QDELETED(src_object))
		return
	if(src_object.ui_act(act_type, payload, src, state))
		SStgui.update_uis(src_object)

