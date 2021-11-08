/*
Hydrogen-based Plasma Weaponry got a bunch of quirks that make them very dangerous to use, but even more rewarding.

The projectile do 100 burn damage on the target, as well as a small explosion, but disapear after traveling a certain distance.

The core concept of this gun is heat management.
Keep firing, and eventually the gun will become too hot and burn your hands. If you keep going even more, then containment of the plasma will fail and burn every bodypart.
Luckily the gun slowly cool down over time, as well as regularly vent its heat.

However, if you fail to secure the hydrogen flask used as ammo, then containment won't be perfect and will get breached on the first shot.
Securing and unsecuring the flask is a long and hard task, and a failure when unsecuring the flask can burn your hands.
*/

/obj/item/gun/hydrogen
	name = "\improper \"Venatori\" hydrogen-plasma gun"
	desc = "A volatile but powerful weapon that uses hydrogen flasks to fire destructive plasma bolts. The brain child of Soteria Director Nakharan Mkne, meant to compete and exceed the church of the absolutes \
	own plasma designs, it succeeded. However, it did so by being extremely dangerous, requiring an intelligent and careful operator who can correctly manage the weapons over heating without being \
	burnt to a crisp."
	icon = 'icons/obj/guns/plasma/hydrogen.dmi'
	icon_state = "plasma"
	origin_tech = list(TECH_COMBAT = 5, TECH_MATERIAL = 5, TECH_PLASMA = 8)
	w_class = ITEM_SIZE_BULKY
	recoil_buildup = 1
	twohanded = TRUE
	max_upgrades = 3
	fire_delay = 10
	fire_sound = 'sound/weapons/lasercannonfire.ogg'
	matter = list(MATERIAL_PLASTEEL = 25, MATERIAL_MHYDROGEN = 5, MATERIAL_OSMIUM = 3, MATERIAL_TRITIUM = 2)
	init_firemodes = list(
		list(mode_name = "standard", mode_desc="A large ball of hydrogen to blow up bulwarks or weak targets", projectile_type = /obj/item/projectile/hydrogen, fire_sound = 'sound/weapons/lasercannonfire.ogg', fire_delay=30, icon="destroy", use_plasma_cost = 10),
		list(mode_name = "overclock", mode_desc="A large ball of volatile hydrogen to blow up cover or targets", projectile_type = /obj/item/projectile/hydrogen/max, fire_sound='sound/effects/supermatter.ogg', fire_delay=50, icon="kill", use_plasma_cost = 20)
	)

	var/projectile_type = /obj/item/projectile/hydrogen
	var/use_plasma_cost = 10 // How much plasma is used per shot
	var/heat_per_shot = 25 // How much heat is gained each shot

	var/obj/item/hydrogen_fuel_cell/flask = null // The flask the gun use for ammo
	var/obj/item/hydrogen_fuel_cell/backpack/connected = null // The backpack the gun is connected to
	var/secured = TRUE // Is the flask secured?
	var/vent_level = 50 // Threshold at which is automatically vent_level
	var/vent_level_timer = 15 // Timer in 2 seconds before the next venting can happen. A value of 15 mean that it will take 30 seconds before the gun can vent itself again.
	var/overheat = 100 // Max heat before overheating.
	// Damage dealt when overheating
	var/overheat_damage = 25 // Applied to the hand holding the gun.


/obj/item/gun/hydrogen/Initialize()
	..()
	flask = new /obj/item/hydrogen_fuel_cell(src) // Give the gun a new flask when mapped in.
	AddComponent(/datum/component/heat, clickTypeToVent = COMSIG_CLICK_CTRL, parentIsGun = TRUE, _heatThresholdSpecial = vent_level, _overheatThreshold = overheat, _heatPerFire = heat_per_shot, _coolPerTick = 2, _ventCooldown = vent_level_timer)
	RegisterSignal(src, COMSIG_HEAT_VENT, .proc/ventEvent)
	RegisterSignal(src, COMSIG_HEAT_OVERHEAT, .proc/handleoverheat)
	update_icon()
	START_PROCESSING(SSobj, src)

/obj/item/gun/hydrogen/Destroy()
	STOP_PROCESSING(SSobj, src)
	..()

/obj/item/gun/hydrogen/examine(mob/user)
	..(user)
	if(!flask)
		to_chat(user, SPAN_NOTICE("Has no flask inserted."))
		return
	if(use_plasma_cost) // So that the bluecross weapon can use 0 plasma
		var/shots_remaining = round(flask.plasma / use_plasma_cost)
		to_chat(user, "Has [shots_remaining] shot\s remaining.")
	if(!secured)
		to_chat(user, SPAN_DANGER("The fuel cell is not secured!"))

	to_chat(user, SPAN_NOTICE("Control-Click to manually vent this weapon's heat."))
	return




// Removing the plasma flask
/obj/item/gun/hydrogen/MouseDrop(over_object)
	if(!connected)
		if(secured)
			to_chat(usr, "The fuel cell is screwed to the gun. You cannot remove it.")
		else if((src.loc == usr) && istype(over_object, /obj/screen/inventory/hand) && eject_item(flask, usr))
			flask = null
			update_icon()

/obj/item/gun/hydrogen/attackby(obj/item/W as obj, mob/living/user as mob)

	// Securing or unsecuring the cell
	if(QUALITY_SCREW_DRIVING)
		if((flask) && !(connected) && !(istype(W, /obj/item/hydrogen_fuel_cell/backpack)))
			var/obj/item/tool/T = W // New var to use tool-only procs.
			if(T.use_tool(user, src, WORKTIME_EXTREMELY_LONG, QUALITY_SCREW_DRIVING, FAILCHANCE_HARD, required_stat = STAT_MEC)) // Skill check. Hard to pass and long to do.
				if(secured)
					user.visible_message(
											SPAN_NOTICE("[user] unsecure the plasma flask."),
											SPAN_NOTICE("You unsecure the plasma flask.")
										)
					secured = FALSE
				else
					user.visible_message(
											SPAN_NOTICE("[user] secure the plasma flask."),
											SPAN_NOTICE("You secure the plasma flask.")
										)
					secured = TRUE
				return
			else // When you fail
				if(prob(75) && secured) // Get burned.
					user.visible_message(
											SPAN_NOTICE("[user] make a mistake while unsecuring the flask and burns \his hand."),
											SPAN_NOTICE("You make a mistake while unsecuring the flask and burns your hand.")
										)
					overheating(user)
				return
		else
			to_chat(user, "There is no flask to remove.")

	// We do not want to insert the backpack, thank you very much.
	if(istype(W, /obj/item/hydrogen_fuel_cell/backpack))
		return


	if(flask && istype(W, /obj/item/hydrogen_fuel_cell))
		to_chat(usr, SPAN_WARNING("[src] is already loaded."))
		return

	if(istype(W, /obj/item/hydrogen_fuel_cell) && insert_item(W, user))
		flask = W
		update_icon()
		return

/obj/item/gun/hydrogen/Process()
	// Check if the gun is attached
	if(connected) // Are we connected to something?
		if(loc != connected) // Are we in the connected object?
			if(loc != connected.loc) // Are we not in the same place?
				src.visible_message("The [src.name] reattaches itself to the [connected.name].")
				usr.remove_from_mob(src)
				forceMove(connected)

/obj/item/gun/hydrogen/consume_next_projectile()
	if(!flask)
		return null
	if(!ispath(projectile_type))
		return null
	if(!flask.use(use_plasma_cost))
		return null
	return new projectile_type(src)

/obj/item/gun/hydrogen/update_icon()
	cut_overlays()
	if(flask && !connected)
		add_overlay("[icon_state]_loaded")
	if(connected)
		add_overlay("[icon_state]_connected")


/////////////////////
///  Custom procs ///
/////////////////////

// Vent the weapon
/obj/item/gun/hydrogen/proc/ventEvent() //lol
	src.visible_message("The [src.name]'s vents open and spew super-heated steam, cooling itself down.")


// The weapon is too hot, burns the user's hand.
/obj/item/gun/hydrogen/proc/overheating()
	src.visible_message(SPAN_DANGER("The [src.name] overheat, burning its wielder's hands!"))
	if(loc == /mob/living)
		var/mob/living/L = loc
	// Burn the hand holding the gun
		if(L.hand == L.l_hand) // Are we using the left arm?
			L.apply_damage(overheat_damage, BURN, def_zone = BP_L_ARM)
		else // If not then it must be the right arm.
			L.apply_damage(overheat_damage, BURN, def_zone = BP_R_ARM)

//
