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


#macro Setting(type, name, setname)
	member:type name()
	{
		return ${This.CommonRef.FindSetting[name]}
	}

	method setname(type value)
	{
		This.CommonRef:AddSetting[name,${value}]
		Config:Save
	}
#endmac

#macro DynamicAddBehavior(name, displayname)
	Dynamic:AddBehavior[name, displayname, ${String[_FILE_].Escape}]
#endmac

#macro DynamicAddMiniMode(name, displayname)
	Dynamic:AddMiniMode[name, displayname, ${String[_FILE_].Escape}]
#endmac