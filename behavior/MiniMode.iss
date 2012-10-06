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

objectdef obj_MiniMode inherits obj_State
{

	method Initialize()
	{
		This[parent]:Initialize
		DynamicAddBehavior("MiniMode", "MiniModes Only")
	}

	method Start()
	{
		UI:Update["obj_MiniMode", "Started", "g"]
		This:AssignStateQueueDisplay[DebugStateList@Debug@ComBotTab@ComBot]
	}
	
	method Stop()
	{
		This:DeactivateStateQueueDisplay
		This:Clear
	}
}