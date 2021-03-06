//Valueables stashes.
//Contain credits and rare materials. Shiny gold and gems
/datum/stash/valueable
	base_type = /datum/stash/valueable
	loot_type = "Valueables"
	contents_list_base = list(/obj/random/credits/c5000 = 1)

	contents_list_random = list(/obj/item/stack/material/diamond/random = 10,
	/obj/item/stack/material/platinum/random = 10,
	/obj/item/stack/material/gold/random = 15,
	/obj/item/stack/material/silver/random = 25,
	/obj/random/credits/c5000 = 30,
	/obj/random/credits/c1000 = 60,
	/obj/random/credits/c500 = 90)

/datum/stash/valueable/poker

	lore = "Logbook <br>\
	Made out like a bandit in poker last night but the boys think there's something to it. It isn't my\
	 damn fault the kids don't know what a fucking tell is. Two hearts does not make a good bluff, \
	 dumbass. I actually think they might shake me down for it, but they don't know the colony like I do.\
	  Here ya go, idiots. Better than a thousand words.<br> %D"

/datum/stash/valueable/sinner

	lore = "Presbyter,<br>\
 I do not know who else to turn to.<br>\
 I have committed a terrible sin.<br>\
 I have envied, stolen, and killed.<br>\
 I do not think I can stand to face judgement for what I have done, save the judgement of God, who will bear down upon me furiously for sins in this life.<br>\
 But I will go to Him bravely. Perhaps He will lessen my agonies in Purgatory before you can return me.<br>\
 I only hope I can pay for all I have done. I have buried Judas and his silver at %D, and will find my own bleeding acre."
	contents_list_external = list(/obj/item/remains/human = 1)


/datum/stash/valueable/pirate
	base_type = /datum/stash/valueable/pirate
	contents_list_extra = list(/obj/item/melee/energy/sword/pirate = 1, /obj/item/clothing/glasses/eyepatch)

/datum/stash/valueable/pirate/treasure
	directions = DIRECTION_IMAGE

	lore = "We, in common accordance with the code of brotherhood, do hereby swear to gather once more in one month's time,<br>\
 at the place of the map, for the recovery of our plunder. <br>\
<br>\
Should any of us fail to assemble, he shall be suspect, and should any plunder be absent, the missing party be hunted unto death. <br>\
This oath we take of the thive's code."
