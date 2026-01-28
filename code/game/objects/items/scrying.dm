/datum/scrying_component
	var/name = "scrying component"

	var/text_cooldown_fail = "I look into NAME_HERE but only see inky smoke. Maybe I should wait."

	var/vision_duration = 8 SECONDS
	var/cooldown_duration = 30 SECONDS
	COOLDOWN_DECLARE(scry_cooldown)

/datum/scrying_component/New()
	. = ..()
	text_cooldown_fail = replacetext(text_cooldown_fail, "NAME_HERE", "\the [name]")

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

	for(var/mob/living/carbon/human/human_target in GLOB.human_list)
		if(human_target.real_name == search_name)
			var/turf/target_turf = get_turf(human_target)
			if(!target_turf)
				continue
			if(HAS_TRAIT(human_target, TRAIT_ANTISCRYING))
				to_chat(user, span_warning("I peer into \the [name], but an impenetrable fog shrouds [search_name]."))
				to_chat(human_target, span_warning("My magical shrouding reacted to something."))
				return
			log_game("SCRYING: [user.real_name] ([user.ckey]) has used the [name] to leer at [human_target.real_name] ([human_target.ckey])")
			ADD_TRAIT(user, TRAIT_NOSSDINDICATOR, "scrying")//Consider changing this -------------------------------------
			var/mob/dead/observer/screye/eye = user.scry_ghost()//Consider changing this -------------------------------------
			if(!eye)//Consider changing this -------------------------------------
				return//Consider changing this -------------------------------------
			eye.ManualFollow(human_target)//Consider changing this -------------------------------------

			COOLDOWN_START(src, scry_cooldown, cooldown_duration)
			user.visible_message(span_danger("[user] stares into \the [name], [user.p_their()] eyes rolling back into [user.p_their()] head."))
			addtimer(CALLBACK(eye, TYPE_PROC_REF(/mob/dead/observer, reenter_corpse)), vision_duration)
			if(!human_target.stat)
				if(human_target.STAPER >= 15)
					if(human_target.mind)
						if(human_target.mind.do_i_know(name = user.real_name))
							to_chat(human_target, span_warning("I can clearly see the face of [user.real_name] staring at me!"))
							to_chat(user, span_warning("[human_target.real_name] stares back at me!"))
							return
					to_chat(human_target, span_warning("I can clearly see the face of an unknown [user.gender == FEMALE ? "woman" : "man"] staring at me!"))
					return
				if(human_target.STAPER >= 11)
					to_chat(human_target, span_warning("I feel a pair of unknown eyes on me."))
			REMOVE_TRAIT(user, TRAIT_NOSSDINDICATOR, "scrying")//Consider changing this -------------------------------------
			return
	to_chat(user, span_warning("I peer into \the [name], but can't find [search_name]."))

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

	var/mob/current_owner

	var/datum/scrying_component/scry_comp
	var/scry_comp_path = /datum/scrying_component/orb

/obj/item/scrying/Initialize(mapload)
	. = ..()
	scry_comp = new scry_comp_path

/obj/item/scrying/eye
	name = "accursed eye"
	desc = "It is pulsating."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state ="scryeye"

	scry_comp_path = /datum/scrying_component/eye


/obj/item/scrying/attack_self(mob/user, params)
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
	scry_comp = new

/obj/structure/nocdevice/attack_hand(mob/user)
	. = ..()
	scry_comp.activate(user)
