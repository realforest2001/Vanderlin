/datum/wound/artery
	name = "Torn Artery"
	sound_effect = list('sound/gore/artery1.ogg', \
						'sound/gore/artery2.ogg', \
						'sound/gore/artery3.ogg')
	severity = WOUND_SEVERITY_SEVERE
	critical = TRUE
	mortal = FALSE
	can_sew = TRUE
	can_cauterize = TRUE
	embed_chance = 0
	werewolf_infection_probability = 50
	sleep_healing = 0
	associated_bclasses = ARTERY_BCLASSES
	min_damage = 5
	min_damage_dividend = 0
	strong_intent_bonus = TRUE
	aimed_intent_bonus = TRUE
	crit_message = list(
		"Blood sprays from %VICTIM's %BODYPART!",
		"Blood rushes from %VICTIM's %BODYPART!",
		"Blood bursts from %VICTIM's %BODYPART with a great force!",
	)
	var/artery_type_override

/datum/wound/artery/can_apply_to_bodypart(obj/item/bodypart/affected)
	. = ..()
	if(affected.status == BODYPART_ROBOTIC)
		return FALSE
	if(!affected.get_incision())
		return FALSE

/datum/wound/artery/can_stack_with(datum/wound/other)
	if(istype(other, /datum/wound/artery) && (type == other.type))
		return FALSE
	return TRUE

/datum/wound/artery/apply_to_bodypart(obj/item/bodypart/affected, silent, crit_message)
	. = ..()
	if(!.)
		return
	var/obj/item/organ/artery/artery
	for(var/obj/item/organ/possible_artery in shuffle(affected.getorganslotlist(ORGAN_SLOT_ARTERY)))
		if(!possible_artery)
			continue
		if(possible_artery.damage >= possible_artery?.maxHealth)
			continue
		if(artery_type_override && !istype(possible_artery, artery_type_override))
			continue
		artery = possible_artery
		break
	if(!artery)
		qdel(src)
		return FALSE
	var/dissection = (severity >= WOUND_SEVERITY_CRITICAL) || ((artery?.maxHealth - artery?.damage) <= (artery?.maxHealth * artery?.tear_damage_multiplier))
	if(dissection)
		artery.dissect()
	else
		artery.tear()
	. = ..()
	affected.temporary_crit_paralysis(10 SECONDS)
	qdel(src)

/datum/wound/artery/neck
	artery_type_override = /obj/item/organ/artery/neck

/datum/wound/artery/chest
	artery_type_override = /obj/item/organ/artery/chest

/datum/wound/artery/dissect
	severity = WOUND_SEVERITY_CRITICAL

/datum/wound/artery/dissect/neck
	artery_type_override = /obj/item/organ/artery/neck
