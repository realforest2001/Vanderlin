/obj/item/organ/appendix
	name = "appendix"
	icon_state = "appendix"
	zone = BODY_ZONE_PRECISE_GROIN
	slot = ORGAN_SLOT_APPENDIX

	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = STANDARD_ORGAN_DECAY

	now_failing = "<span class='warning'>An explosion of pain erupts in your lower right abdomen!</span>"
	now_fixed = "<span class='info'>The pain in your abdomen has subsided.</span>"

	organ_volume = 0.5
	max_blood_storage = 2.5
	current_blood = 2.5
	blood_req = 0.5
	oxygen_req = 0.25
	nutriment_req = 0.35
	hydration_req = 0.2

/obj/item/organ/appendix/update_icon_state()
	icon_state = "appdendix[inflamed ? "inflamed" : ""]"
	return ..()

/obj/item/organ/appendix/update_name()
	name = "[inflamed ? "inflamed " : ""]appendix"
	return ..()

/obj/item/organ/appendix/organ_failure(delta_time)
	inflamation_stage = TRUE
	owner.adjustToxLoss(0.5 * delta_time, FALSE, TRUE) //forced to ensure people don't use it to gain tox as slime person
	return ..() || ORGAN_PROCESS_UPDATE_HEALTH

/obj/item/organ/appendix/Remove(mob/living/carbon/M, special = 0)
	update_appearance(UPDATE_ICON_STATE | UPDATE_NAME)
	..()

/obj/item/organ/appendix/prepare_eat()
	var/obj/S = ..()
	if(inflamed)
		S.reagents.add_reagent(/datum/reagent/toxin/bad_food, 5)
	return S
