/*

ComBot  Copyright ? 2012  Tehtsuo and Vendan

This file is part of ComBot.

ComBot is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ComBot is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ComBot.  If not, see <http://www.gnu.org/licenses/>.

*/

objectdef obj_PriorityTargets
{
	variable index:string Scramble
	variable index:string Neut
	variable index:string ECM
	variable index:string Other

	method Initialize()
	{
	
		This.Scramble:Insert["Angel Frigate Vessel"]
		This.Scramble:Insert["Arch Angel Hijacker"]
		This.Scramble:Insert["Arch Angel Outlaw"]
		This.Scramble:Insert["Arch Angel Rogue"]
		This.Scramble:Insert["Arch Angel Thug"]
		This.Scramble:Insert["Arch Gistii Hijacker"]
		This.Scramble:Insert["Arch Gistii Outlaw"]
		This.Scramble:Insert["Arch Gistii Rogue"]
		This.Scramble:Insert["Arch Gistii Thug"]
		This.Scramble:Insert["Terrorist Leader"]
		This.Scramble:Insert["Elder Corpii Follower"]
		This.Scramble:Insert["Elder Corpii Herald"]
		This.Scramble:Insert["Elder Corpii Upholder"]
		This.Scramble:Insert["Elder Corpii Worshiper"]
		This.Scramble:Insert["Dire Pithi Arrogator"]
		This.Scramble:Insert["Dire Pithi Imputor"]
		This.Scramble:Insert["Dire Pithi Infiltrator"]
		This.Scramble:Insert["Dire Pithi Invader"]
		This.Scramble:Insert["Pithi Defender"]
		This.Scramble:Insert["Yukiro Demense"]
		This.Scramble:Insert["Centii Loyal Minion"]
		This.Scramble:Insert["Centii Loyal Ravener"]
		This.Scramble:Insert["Centii Loyal Scavenger"]
		This.Scramble:Insert["Centii Loyal Servant"]
		This.Scramble:Insert["Coreli Guardian Agent"]
		This.Scramble:Insert["Coreli Guardian Initiate"]
		This.Scramble:Insert["Coreli Guardian Scout"]
		This.Scramble:Insert["Coreli Guardian Spy"]
		This.Scramble:Insert["Brute Render Alvi"]
		This.Scramble:Insert["COSMOS Marauder Drone"]
		This.Scramble:Insert["COSMOS Ripper Drone"]
		This.Scramble:Insert["Strain Decimator Alvi"]
		This.Scramble:Insert["Strain Infester Alvi"]
		This.Scramble:Insert["Strain Splinter Alvi"]
		This.Scramble:Insert["Elder Blood Follower"]
		This.Scramble:Insert["Elder Blood Herald"]
		This.Scramble:Insert["Elder Blood Upholder"]
		This.Scramble:Insert["Elder Blood Worshipper"]
		This.Scramble:Insert["Dire Guristas Arrogator"]
		This.Scramble:Insert["Dire Guristas Imputor"]
		This.Scramble:Insert["Dire Guristas Infiltrator"]
		This.Scramble:Insert["Dire Guristas Invader"]
		This.Scramble:Insert["Sansha's Loyal Minion"]
		This.Scramble:Insert["Sansha's Loyal Ravener"]
		This.Scramble:Insert["Sansha's Loyal Scavanger"]
		This.Scramble:Insert["Sansha's Loyal Servant"]
		This.Scramble:Insert["Guardian Agent"]
		This.Scramble:Insert["Guardian Initiate"]
		This.Scramble:Insert["Guardian Scout"]
		This.Scramble:Insert["Guardian Spy"]
		This.Scramble:Insert["Strain Decimator Drone"]
		This.Scramble:Insert["Strain Infester Drone"]
		This.Scramble:Insert["Strain Render Drone"]
		This.Scramble:Insert["Strain Splinter Drone"]
		
		; Neut
		This.Neut:Insert["Elder Corpum Sage"]
		This.Neut:Insert["Elder Corpum Revenant"]
		This.Neut:Insert["Elder Corpum Priest"]
		This.Neut:Insert["Elder Corpum Arch Templar"]
		This.Neut:Insert["Corpum Priest"]
		This.Neut:Insert["Corpum Sage"]
		This.Neut:Insert["Dark Corpum Priest"]
		This.Neut:Insert["Dark Corpum Sage"]
		This.Neut:Insert["Blood Priest"]
		This.Neut:Insert["Blood Sage"]
		This.Neut:Insert["Elder Blood Arch Templar"]
		This.Neut:Insert["Elder Blood Priest"]
		This.Neut:Insert["Elder Blood Revenant"]
		This.Neut:Insert["Elder Blood Sage"]
		This.Neut:Insert["TEST DRAINER"]
		This.Neut:Insert["Dark Blood Priest"]
		This.Neut:Insert["Dark Blood Sage"]
		This.Neut:Insert["Dark Blood Archbishop"]
		This.Neut:Insert["Dark Blood Harbinger"]
		This.Neut:Insert["Corpus Archbishop"]
		This.Neut:Insert["Corpus Harbinger"]
		This.Neut:Insert["Dark Corpus Archbishop"]
		This.Neut:Insert["Dark Corpus Harbinger"]
		This.Neut:Insert["Blood Archbishop"]
		This.Neut:Insert["Blood Harbinger"]
		
		; ECM
		This.ECM:Insert["Dread Guristas Saboteur"]
		This.ECM:Insert["Dread Guristas Despoiler"]
		This.ECM:Insert["Ace Saboteur"]
		This.ECM:Insert["Ace Despoiler"]
		This.ECM:Insert["Dire Guristas Despoiler"]
		This.ECM:Insert["Dire Guristas Saboteur"]
		This.ECM:Insert["Guristas Despoiler"]
		This.ECM:Insert["Guristas Saboteur"]
		This.ECM:Insert["Dire Pithi Saboteur"]
		This.ECM:Insert["Dread Pithi Despoiler"]
		This.ECM:Insert["Dread Pithi Saboteur"]
		This.ECM:Insert["Outlaw Despoiler"]
		This.ECM:Insert["Outlaw Saboteur"]
		This.ECM:Insert["Pithum Nullifier"]
		This.ECM:Insert["Pithum Murderer"]
		This.ECM:Insert["Pithum Killer"]
		This.ECM:Insert["Pithum Annihilator"]
		This.ECM:Insert["Dread Pithum Nullifier"]
		This.ECM:Insert["Dread Pithum Murderer"]
		This.ECM:Insert["Dread Pithum Killer"]
		This.ECM:Insert["Dread Pithum Annihilator"]
		This.ECM:Insert["Dire Pithum Nullifier"]
		This.ECM:Insert["Dire Pithum Murderer"]
		This.ECM:Insert["Dire Pithum Killer"]
		This.ECM:Insert["Dire Pithum Annihilator"]
		This.ECM:Insert["Angel Cruiser Vessel"]
		This.ECM:Insert["Dire Guristas Annihilator"]
		This.ECM:Insert["Dire Guristas Killer"]
		This.ECM:Insert["Dire Guristas Murderer"]
		This.ECM:Insert["Dire Guristas Nullifier"]
		This.ECM:Insert["Gunslinger Killer"]
		This.ECM:Insert["Gunslinger Murderer"]
		This.ECM:Insert["Guristas Annihilator"]
		This.ECM:Insert["Guristas Killer"]
		This.ECM:Insert["Guristas Murderer"]
		This.ECM:Insert["Guristas Nullifier"]
		This.ECM:Insert["Deuce Killer"]
		This.ECM:Insert["Deuce Murderer"]
		This.ECM:Insert["Dread Guristas Killer"]
		This.ECM:Insert["Dread Guristas Annihilator"]
		This.ECM:Insert["Dread Guristas Murderer"]
		This.ECM:Insert["Dread Guristas Nullifier"]
		This.ECM:Insert["Dread Guristas Exterminator"]
		This.ECM:Insert["Dread Guristas Eliminator"]
		This.ECM:Insert["Dread Pith Eliminator"]
		This.ECM:Insert["Dread Pith Exterminator"]
		This.ECM:Insert["Pith Eliminator"]
		This.ECM:Insert["Pith Exterminator"]
		This.ECM:Insert["Guristas Eliminator"]
		This.ECM:Insert["Guristas Exterminator"]
		
		; Other
		This.Other:Insert["True Sansha's Slavehunter"]
		This.Other:Insert["True Sansha's Savage"]
		This.Other:Insert["Sansha's Slavehunter"]
		This.Other:Insert["Sansha's Savage"]
		This.Other:Insert["Sansha's Loyal Slavehunter"]
		This.Other:Insert["Sansha's Loyal Savage"]
		This.Other:Insert["Domination Nomad"]
		This.Other:Insert["Domination Ruffian"]
		This.Other:Insert["Psycho Nomad"]
		This.Other:Insert["Psycho Ruffian"]
		This.Other:Insert["Arch Angel Ruffian"]
		This.Other:Insert["Arch Angel Nomad"]
		This.Other:Insert["Angel Webifier"]
		This.Other:Insert["Angel Viper"]
		This.Other:Insert["Angel Ruffian"]
		This.Other:Insert["Angel Nomad"]
		This.Other:Insert["Cyber Nomad"]
		This.Other:Insert["Cyber Ruffian"]
		This.Other:Insert["Arch Gistii Nomad"]
		This.Other:Insert["Arch Gistii Ruffian"]
		This.Other:Insert["Gistii Domination Nomad"]
		This.Other:Insert["Gistii Domination Ruffian"]
		This.Other:Insert["Gistii Ruffian"]
		This.Other:Insert["Elder Corpii Seeker"]
		This.Other:Insert["Elder Corpii Collector"]
		This.Other:Insert["Dark Corpii Seeker"]
		This.Other:Insert["Dark Corpii Collector"]
		This.Other:Insert["Corpii Seeker"]
		This.Other:Insert["Corpii Collector"]
		This.Other:Insert["Blood Wraith"]
		This.Other:Insert["Blood Disciple"]
		This.Other:Insert["Guristas Kyoukan"]
		This.Other:Insert["Guristas Webifier"]
		This.Other:Insert["Pithi Despoiler"]
		This.Other:Insert["Pithi Saboteur"]
		This.Other:Insert["Centii Savage"]
		This.Other:Insert["Centii Slavehunter"]
		This.Other:Insert["Sansha's Berserker"]
		This.Other:Insert["Sansha's Demon"]
		This.Other:Insert["True Centii Savage"]
		This.Other:Insert["True Centii Slavehunter"]
		This.Other:Insert["Coreli Guardian Patroller"]
		This.Other:Insert["Coreli Guardian Watchman"]
		This.Other:Insert["Coreli Patroller"]
		This.Other:Insert["Coreli Watchman"]
		This.Other:Insert["Guardian Veteran"]
		This.Other:Insert["Shadow Coreli Patroller"]
		This.Other:Insert["Shadow Coreli Watchman"]
		This.Other:Insert["Spider Drone I"]
		This.Other:Insert["Spider Drone II"]
		This.Other:Insert["Blood Collector"]
		This.Other:Insert["Blood Seeker"]
		This.Other:Insert["Elder Blood Collector"]
		This.Other:Insert["Elder Blood Seeker"]
		This.Other:Insert["Warrior Collector"]
		This.Other:Insert["Warrior Seeker"]
		This.Other:Insert["Dark Blood Collector"]
		This.Other:Insert["Dark Blood Seeker"]
		This.Other:Insert["Sellsword Collector"]
		This.Other:Insert["Sellsword Seeker"]
		This.Other:Insert["Crook Patroller"]
		This.Other:Insert["Crook Watchman"]
		This.Other:Insert["Guardian Patroller"]
		This.Other:Insert["Guardian Watchman"]
		This.Other:Insert["Serpentis Patroller"]
		This.Other:Insert["Serpentis Watchman"]
		This.Other:Insert["Marauder Patroller"]
		This.Other:Insert["Marauder Watchman"]
		This.Other:Insert["Shadow Serpentis Patroller"]
		This.Other:Insert["Shadow Serpentis Watchman"]
		This.Other:Insert["Domination Smasher"]
		This.Other:Insert["Domination Defeater"]
		This.Other:Insert["Domination Crusher"]
		This.Other:Insert["Domination Breaker"]
		This.Other:Insert["Arch Gistum Crusher"]
		This.Other:Insert["Arch Gistum Smasher"]
		This.Other:Insert["Gistum Breaker"]
		This.Other:Insert["Gistum Crusher"]
		This.Other:Insert["Gistum Defeater"]
		This.Other:Insert["Gistum Domination Crusher"]
		This.Other:Insert["Gistum Domination Defeater"]
		This.Other:Insert["Gistum Domination Smasher"]
		This.Other:Insert["Gistum Smasher"]
		This.Other:Insert["Society of Conscious Thought Cruiser"]
		This.Other:Insert["Angel Breaker"]
		This.Other:Insert["Angel Crusher"]
		This.Other:Insert["Angel Defeater"]
		This.Other:Insert["Angel Smasher"]
		This.Other:Insert["Arch Angel Crusher"]
		This.Other:Insert["Arch Angel Smasher"]
		This.Other:Insert["Corpum Arch Templar"]
		This.Other:Insert["Corpum Revenant"]
		This.Other:Insert["Dark Corpum Revenant"]
		This.Other:Insert["Centum Beast"]
		This.Other:Insert["Centum Execrator"]
		This.Other:Insert["Centum Juggernaut"]
		This.Other:Insert["Centum Loyal Beast"]
		This.Other:Insert["Centum Loyal Execrator"]
		This.Other:Insert["Centum Loyal Juggernaut"]
		This.Other:Insert["Centum Loyal Slaughterer"]
		This.Other:Insert["Centum Slaughterer"]
		This.Other:Insert["True Centum Beast"]
		This.Other:Insert["True Centum Execrator"]
		This.Other:Insert["True Centum Juggernaut"]
		This.Other:Insert["True Centum Slaughterer"]
		This.Other:Insert["Corelum Chief Guard"]
		This.Other:Insert["Corelum Chief Patroller"]
		This.Other:Insert["Corelum Chief Safeguard"]
		This.Other:Insert["Corelum Chief Watchman"]
		This.Other:Insert["Corelum Guardian Chief Guard"]
		This.Other:Insert["Corelum Guardian Chief Patroller"]
		This.Other:Insert["Corelum Guardian Chief SafeGuard"]
		This.Other:Insert["Corelum Guardian Chief Watchman"]
		This.Other:Insert["Shadow Corelum Chief Guard"]
		This.Other:Insert["Shadow Corelum Chief Patroller"]
		This.Other:Insert["Shadow Corelum Chief Safeguard"]
		This.Other:Insert["Shadow Corelum Chief Watchman"]
		This.Other:Insert["Underground Circus Ringmaster"]
		This.Other:Insert["Blood Revenant"]
		This.Other:Insert["Blood Arch Templar"]
		This.Other:Insert["Dark Blood Arch Templar"]
		This.Other:Insert["Dark Blood Revenant"]
		This.Other:Insert["Sansha's Beast"]
		This.Other:Insert["Sansha's Juggernaut"]
		This.Other:Insert["Sansha's Loyal Beast"]
		This.Other:Insert["Sansha's Loyal Execrator"]
		This.Other:Insert["Sansha's Loyal Juggernaut"]
		This.Other:Insert["Sansha's Loyal Slaughterer"]
		This.Other:Insert["Sansha's Slaughterer"]
		This.Other:Insert["True Sansha's Execrator"]
		This.Other:Insert["True Sansha's Beast"]
		This.Other:Insert["True Sansha's Juggernaut"]
		This.Other:Insert["True Sansha's Slaughterer"]
		This.Other:Insert["Guardian Chief Guard"]
		This.Other:Insert["Guardian Chief Patroller"]
		This.Other:Insert["Guardian Chief Safeguard"]
		This.Other:Insert["Guardian Chief Watchman"]
		This.Other:Insert["Serpentis Chief Guard"]
		This.Other:Insert["Serpentis Chief Patroller"]
		This.Other:Insert["Serpentis Chief Safeguard"]
		This.Other:Insert["Serpentis Chief Watchman"]
		This.Other:Insert["Shadow Serpentis Chief Guard"]
		This.Other:Insert["Shadow Serpentis Chief Patroller"]
		This.Other:Insert["Shadow Serpentis Chief Safeguard"]
		This.Other:Insert["Shadow Serpentis Chief Watchman"]
		This.Other:Insert["Domination Nephilim"]
		This.Other:Insert["Domination Saint"]
		This.Other:Insert["Angel Nephilim"]
		This.Other:Insert["Angel Saint"]
		This.Other:Insert["Gist Domination Nephilim"]
		This.Other:Insert["Gist Domination Saint"]
		This.Other:Insert["Gist Nephilim"]
		This.Other:Insert["Gist Saint"]
		This.Other:Insert["Centus Beast Lord"]
		This.Other:Insert["Centus Plague Lord"]
		This.Other:Insert["True Centus Beast Lord"]
		This.Other:Insert["True Centus Plague Lord"]
		This.Other:Insert["Core Flotilla Admiral"]
		This.Other:Insert["Core Vice Admiral"]
		This.Other:Insert["Shadow Core Flotilla Admiral"]
		This.Other:Insert["Shadow Core Vice Admiral"]
		This.Other:Insert["Anti-Stabilizer Drone"]
		This.Other:Insert["Sansha's Beast Lord"]
		This.Other:Insert["Sansha's Plague Lord"]
		This.Other:Insert["True Sansha's Beast Lord"]
		This.Other:Insert["True Sansha's Plague Lord"]
		This.Other:Insert["Serpentis Flotilla Admiral"]
		This.Other:Insert["Serpentis Vice Admiral"]
		This.Other:Insert["Shadow Serpentis Flotilla Admiral"]
		This.Other:Insert["Shadow Serpentis Vice Admiral"]

	}

}