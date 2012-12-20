/*

ComBot  Copyright � 2012  Tehtsuo and Vendan

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

objectdef obj_Configuration_AutoThrust
{
	variable string SetName = "AutoThrust"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["obj_AutoThrust", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.CommonRef:AddSetting[Approach_Threshold, 50]
		This.CommonRef:AddSetting[KeepAtRange_Threshold, 50]
		This.CommonRef:AddSetting[Orbit_Threshold, 50]
		This.CommonRef:AddSetting[Velocity_Trigger, 50]
		This.CommonRef:AddSetting[Velocity_Threshold, 50]
	}

	Setting(bool, NeverDeactivate, SetNeverDeactivate)
	Setting(bool, Approach, SetApproach)
	Setting(int, Approach_Threshold, SetApproach_Threshold)
	Setting(bool, KeepAtRange, SetKeepAtRange)
	Setting(int, KeepAtRange_Threshold, SetKeepAtRange_Threshold)
	Setting(bool, Orbit, SetOrbit)
	Setting(int, Orbit_Threshold, SetOrbit_Threshold)
	Setting(bool, Velocity, SetVelocity)
	Setting(int, Velocity_Trigger, SetVelocity_Trigger)
	Setting(int, Velocity_Threshold, SetVelocity_Threshold)

	
}

objectdef obj_AutoThrust inherits obj_State
{
	variable obj_Configuration_AutoThrust Config
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[100]
		This.NonGameTiedPulse:Set[TRUE]
		DynamicAddMiniMode("AutoThrust", "AutoThrust")
	}
	
	method Start()
	{
		This:QueueState["AutoThrust"]
	}
	
	method Stop()
	{
		This:Clear
	}
	
	member:bool AutoThrust()
	{
		variable bool TurnOff=TRUE
	
		if !${Client.InSpace}
		{
			return FALSE
		}
		if ${Me.ToEntity.IsCloaked}
		{
			return FALSE
		}
		
		if !${Config.NeverDeactivate}
		{
			if 	${Config.Approach}
			{
				if 	${Ship.ModuleList_AB_MWD.ActiveCount} &&\
					${MyShip.CapacitorPct} <= ${Config.Approach_Threshold}
				{
					Ship.ModuleList_AB_MWD:Deactivate
					return FALSE
				}
				if 	${Me.ToEntity.Mode} == 1 &&\
					${Me.ToEntity.FollowRange} == 50
				{
					TurnOff:Set[FALSE]
				}
			}
			if 	${Config.Orbit}
			{
				if 	${Ship.ModuleList_AB_MWD.ActiveCount} &&\
					${MyShip.CapacitorPct} <= ${Config.Orbit_Threshold}
				{
					Ship.ModuleList_AB_MWD:Deactivate
					return FALSE
				}
				if 	${Me.ToEntity.Mode} == 4
				{
					TurnOff:Set[FALSE]
				}
			}
			if 	${Config.KeepAtRange}
			{
				if 	${Ship.ModuleList_AB_MWD.ActiveCount} &&\
					${MyShip.CapacitorPct} <= ${Config.KeepAtRange_Threshold}
				{
					Ship.ModuleList_AB_MWD:Deactivate
					return FALSE
				}
				if 	${Me.ToEntity.Mode} == 1 &&\
					${Me.ToEntity.FollowRange} > 50
				{
					TurnOff:Set[FALSE]
				}
			}
			if 	${Config.Velocity}
			{
				if 	${Ship.ModuleList_AB_MWD.ActiveCount} &&\
					${MyShip.CapacitorPct} <= ${Config.Velocity_Threshold}
				{
					Ship.ModuleList_AB_MWD:Deactivate
					return FALSE
				}
				
				if	${Me.ToEntity.Mode} != 2
				{
					TurnOff:Set[FALSE]
				}
			}

			if ${TurnOff}
			{
				if ${Ship.ModuleList_AB_MWD.ActiveCount}
				{
					Ship.ModuleList_AB_MWD:Deactivate
				}
				return FALSE
			}
		}
		
		
		
		
		
		if 	${Config.Approach} &&\
			!${Ship.ModuleList_AB_MWD.ActiveCount} &&\
			${MyShip.CapacitorPct} > ${Config.Approach_Threshold} &&\
			${Me.ToEntity.Mode} == 1 &&\
			${Me.ToEntity.FollowRange} == 50
		{
				Ship.ModuleList_AB_MWD:Activate
				return FALSE
		}
		if 	${Config.Orbit} &&\
			!${Ship.ModuleList_AB_MWD.ActiveCount} &&\
			${MyShip.CapacitorPct} > ${Config.Orbit_Threshold} &&\
			${Me.ToEntity.Mode} == 4
		{
				Ship.ModuleList_AB_MWD:Activate
				return FALSE
		}
		if 	${Config.KeepAtRange} &&\
			!${Ship.ModuleList_AB_MWD.ActiveCount} &&\
			${MyShip.CapacitorPct} > ${Config.KeepAtRange_Threshold} &&\
			${Me.ToEntity.Mode} == 1 &&\
			${Me.ToEntity.FollowRange} > 50
		{
				Ship.ModuleList_AB_MWD:Activate
				return FALSE
		}
		
		if 	${Config.Velocity} &&\
			!${Ship.ModuleList_AB_MWD.ActiveCount} &&\
			${MyShip.CapacitorPct} > ${Config.Velocity_Threshold} &&\
			${Math.Calc[${Me.ToEntity.Velocity} / ${Me.ToEntity.MaxVelocity}]} >= ${Math.Calc[${Config.Velocity_Trigger} * .01]}
		{
				Ship.ModuleList_AB_MWD:Activate
				return FALSE
		}
		
		
		return FALSE
	}

	method Flee()
	{
	}
}