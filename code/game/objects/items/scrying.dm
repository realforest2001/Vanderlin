/datum/scrying_component
	var/name = "scrying component"

	var/text_cooldown_fail = "I look into NAME_HERE but only see inky smoke. Maybe I should wait."

	var/vision_duration = 8 SECONDS
	var/cooldown_duration = 30 SECONDS

	var/mob/scry_eye/scrying_eye
	var/mob/living/carbon/held_user
	COOLDOWN_DECLARE(scry_cooldown)

/datum/scrying_component/New(var/obj/item/scrying/parent)
	. = ..()
	text_cooldown_fail = replacetext(text_cooldown_fail, "NAME_HERE", "\the [name]")
	if(!parent)
		return
	RegisterSignal(parent, COMSIG_PARENT_QDELETING, PROC_REF(handle_parent_del), parent)

/datum/scrying_component/proc/handle_parent_del(var/obj/item/scrying/parent)
	SIGNAL_HANDLER
	parent?.scry_comp = null
	qdel(src)

/datum/scrying_component/proc/activate(mob/living/user)
	if(!pass_extra_checks())
		return FALSE

	if(!COOLDOWN_FINISHED(src, scry_cooldown))
		to_chat(user, span_warning(text_cooldown_fail))
		return FALSE

	var/search_name = stripped_input(user, "Who are you looking for?", name)
	if(!search_name)
		return FALSE

	if(!user.mind || !user.mind.do_i_know(name = search_name))
		to_chat(user, span_warning("I don't know anyone by that name."))
		return FALSE

	//check is applied twice to prevent someone from bypassing the cooldown
	if(!COOLDOWN_FINISHED(src, scry_cooldown))
		to_chat(user, span_warning(text_cooldown_fail))
		return FALSE

	var/mob/living/carbon/human/found_target
	for(var/mob/living/carbon/human/human_target in GLOB.human_list)
		if(human_target.real_name == search_name)
			var/turf/target_turf = get_turf(human_target)
			if(!target_turf)
				message_admins("SCRY DEBUG: NO TURF")
				continue
			found_target = human_target
			break

	held_user = user
	if(HAS_TRAIT(found_target, TRAIT_ANTISCRYING))
		to_chat(user, span_warning("I peer into \the [name], but an impenetrable fog shrouds [search_name]."))
		to_chat(found_target, span_warning("My magical shrouding reacted to something."))
		held_user = null
		return

	create_eye()
	if(!scrying_eye)
		remove_eye(TRUE)
		message_admins("SCRY DEBUG: NO EYE")
		return

	if(found_target.stat)
		to_chat(user, span_warning("I peer into \the [name], but can't find [search_name]."))
		remove_eye(TRUE)
		return FALSE

	log_game("SCRYING: [user.real_name] ([user.ckey]) has used the [name] to leer at [found_target.real_name] ([found_target.ckey])")

	var/real_cooldown = cooldown_duration + vision_duration
	COOLDOWN_START(src, scry_cooldown, real_cooldown)
	user.visible_message(span_danger("[user] stares into \the [name], [user.p_their()] eyes rolling back into [user.p_their()] head."), span_warning("My eyes roll into the back of my head as I'm lost in the depths of the orb."))
	scrying_eye.orbit(found_target)
	if(found_target.STAPER >= 15)
		if(found_target.mind)
			if(found_target.mind.do_i_know(name = user.real_name))
				to_chat(found_target, span_warning("I can clearly see the face of [user.real_name] staring at me!"))
				to_chat(user, span_warning("[found_target.real_name] stares back at me!"))
				message_admins("SCRY DEBUG: WATCHING AWARE FULLY")
				return TRUE
		to_chat(found_target, span_warning("I can clearly see the face of an unknown [user.gender == FEMALE ? "woman" : "man"] staring at me!"))
		message_admins("SCRY DEBUG: WATCHING AWARE MORE")
		return TRUE
	if(found_target.STAPER >= 11)
		to_chat(found_target, span_warning("I feel a pair of unknown eyes on me."))
		message_admins("SCRY DEBUG: WATCHING AWARE")
	message_admins("SCRY DEBUG: WATCHING")
	return TRUE

/datum/scrying_component/proc/create_eye()
	if(!held_user)
		return FALSE
	scrying_eye = new
	scrying_eye.component = src
	held_user.reset_perspective(scrying_eye)
	held_user.Immobilize(vision_duration)
	held_user.overlay_fullscreen("scrying", /atom/movable/screen/backhudl/obs)
	addtimer(CALLBACK(src, PROC_REF(remove_eye)), vision_duration)

/datum/scrying_component/proc/remove_eye(early = FALSE)
	message_admins("SCRY DEBUG: REMOVE CALL")
	if(!held_user)
		return FALSE
	held_user.reset_perspective(held_user)
	held_user.clear_fullscreen("scrying")
	if(early)
		held_user.SetImmobilized(2 SECONDS)
	QDEL_NULL(scrying_eye)
	held_user = null


/datum/scrying_component/proc/pass_extra_checks(mob/living/user)
	return TRUE

/datum/scrying_component/orb
	name = "Scrying Orb"

/datum/scrying_component/eye
	name = "Accursed Eye"
	cooldown_duration = 5 MINUTES

/datum/scrying_component/mirror

/datum/scrying_component/telescope
	text_cooldown_fail = "I peer into the sky but cannot focus the lens on the face of Noc. Maybe I should wait."

/datum/scrying_component/telescope/pass_extra_checks(mob/living/user)
	var/mob/living/carbon/human/human_user = user
	if(!ishuman(human_user) || !human_user.virginity)
		to_chat(human_user, span_notice("Noc looks angry with me..."))
		return FALSE
	return TRUE

/////////////////////////////////////////Scrying///////////////////

/obj/item/scrying
	name = "scrying orb"
	desc = "On its glass depths, you can scry on many unsuspecting beings..."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state ="scrying"
	throw_speed = 3
	throw_range = 7
	throwforce = 15
	damtype = BURN
	force = 15
	hitsound = 'sound/blank.ogg'
	sellprice = 30
	dropshrink = 0.6

	grid_height = 32
	grid_width = 32

	var/datum/scrying_component/scry_comp
	var/scry_comp_path = /datum/scrying_component/orb

/obj/item/scrying/Initialize(mapload)
	. = ..()
	scry_comp = new scry_comp_path(src)

/obj/item/scrying/eye
	name = "accursed eye"
	desc = "It is pulsating."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state ="scryeye"

	scry_comp_path = /datum/scrying_component/eye


/obj/item/scrying/attack_self(mob/user, list/modifiers)
	. = ..()
	scry_comp.activate(user)

//23.08.2025
//nocdevice depreciated?

/*	..................   NOC Device (Fixed scrying ball)   ................... */
/obj/structure/nocdevice
	name = "NOC Device"
	desc = "An intricate lunar observation machine, that allows its user to study the face of Noc in the sky, reflecting the true whereabouts of hidden beings..."
	icon = 'icons/roguetown/misc/96x96.dmi'
	icon_state = "nocdevice"
	plane = -1
	layer = 4.2
	var/datum/scrying_component/telescope/scry_comp

/obj/structure/nocdevice/Initialize()
	. = ..()
	scry_comp = new(src)

/obj/structure/nocdevice/attack_hand(mob/user)
	. = ..()
	scry_comp.activate(user)




/*	..................   THE EYE   ................... */
/mob/scry_eye
	sight = SEE_TURFS | SEE_MOBS | SEE_OBJS
	see_in_dark = 100
	hud_type = /datum/hud/obs
	invisibility = INVISIBILITY_GHOST
	see_invisible = SEE_INVISIBLE_LIVING
	var/datum/scrying_component/component
	var/moving_eye = FALSE

/mob/scry_eye/blackmirror

/mob/scry_eye/Move(n, direct)
	if(!moving_eye)
		return
	..()

/mob/scry_eye/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, list/message_mods = list(), original_message)
	if(!component)
		qdel(src)
		return
	component.held_user.Hear(message, speaker, message_language, raw_message, radio_freq, spans, message_mods, original_message)
	return






/* VAMPIRE EYE */
/mob/scry_eye/eye_of_night
	sight = 0
	see_in_dark = 2
	invisibility = INVISIBILITY_GHOST
	see_invisible = SEE_INVISIBLE_GHOST

	var/mob/living/carbon/human/vampirelord = null
	icon_state = "arcaneeye"
	hud_type = /datum/hud/eye
	moving_eye = TRUE

/mob/scry_eye/eye_of_night/proc/scry_tele()
	set category = "RoleUnique.Arcane Eye"
	set name = "Teleport"
	set desc= "Teleport to a location"
	set hidden = 0

	if(!is_scryeye(usr))
		to_chat(usr, span_warning("You're not an Eye!"))
		return
	var/list/filtered = list()
	for(var/area/A as anything in get_sorted_areas())
		if(A.area_flags & (HIDDEN_AREA|NO_TELEPORT))
			continue
		filtered += A
	var/area/thearea  = input("Area to jump to", "VANDERLIN") as null|anything in filtered

	if(!thearea)
		return

	var/list/L = list()
	for(var/turf/T in get_area_turfs(thearea.type))
		L+=T

	if(!L || !L.len)
		to_chat(usr, span_warning("No area available."))
		return

	usr.forceMove(pick(L))

/mob/scry_eye/eye_of_night/Initialize()
	. = ..()
	var/list/verbs = list(
		/mob/scry_eye/eye_of_night/proc/scry_tele,
		/mob/scry_eye/eye_of_night/proc/cancel_scry,
		/mob/scry_eye/eye_of_night/proc/eye_down,
		/mob/scry_eye/eye_of_night/proc/eye_up,
		/mob/scry_eye/eye_of_night/proc/vampire_telepathy
	)
	add_verb(src, verbs)
	name = "Arcane Eye"
	grant_all_languages()

/mob/scry_eye/eye_of_night/proc/cancel_scry()
	set category = "RoleUnique.Arcane Eye"
	set name = "Cancel Eye"
	set desc= "Return to Body"

	if(vampirelord)
		vampirelord.ckey = ckey
		qdel(src)
	else
		to_chat(src, "My body has been destroyed! I'm trapped!")

/mob/scry_eye/eye_of_night/Crossed(mob/living/L)
	if(istype(L, /mob/living/carbon/human))
		var/mob/living/carbon/human/V = L
		var/holyskill = V.get_skill_level(/datum/skill/magic/holy)
		var/magicskill = V.get_skill_level(/datum/skill/magic/arcane)
		if(magicskill >= 2)
			to_chat(V, "<font color='red'>An ancient and unusual magic looms in the air around you.</font>")
			return
		if(holyskill >= 2)
			to_chat(V, "<font color='red'>An ancient and unholy magic looms in the air around you.</font>")
			return
		if(prob(20))
			to_chat(V, "<font color='red'>You feel like someone is watching you, or something.</font>")
			return

/mob/scry_eye/eye_of_night/proc/vampire_telepathy()
	set name = "Telepathy"
	set category = "RoleUnique.Arcane Eye"

	var/msg = input("Send a message.", "Command") as text|null
	if(!msg)
		return
	for(var/datum/mind/V in SSmapping.retainer.vampires)
		to_chat(V, span_boldnotice("A message from [src.real_name]:[msg]"))
	for(var/datum/mind/D in SSmapping.retainer.death_knights)
		to_chat(D, span_boldnotice("A message from [src.real_name]:[msg]"))
	for(var/mob/scry_eye/eye_of_night/A in GLOB.mob_list)
		to_chat(A, span_boldnotice("A message from [src.real_name]:[msg]"))

/mob/scry_eye/eye_of_night/proc/eye_up()
	set category = "RoleUnique.Arcane Eye"
	set name = "Move Up"

	if(zMove(UP, TRUE))
		to_chat(src, span_notice("I move upwards."))

/mob/scry_eye/eye_of_night/proc/eye_down()
	set category = "RoleUnique.Arcane Eye"
	set name = "Move Down"

	if(zMove(DOWN, TRUE))
		to_chat(src, span_notice("I move down."))
