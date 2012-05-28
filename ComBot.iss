#if ${ISXEVE(exists)}
#else
	#error ComBot requires ISXEVE to be loaded before running
#endif

#include core/Defines.iss
#include core/obj_ComBotUI.iss
#include core/obj_ComBot.iss

#include core/obj_Game.iss
#include core/obj_Move.iss
#include core/obj_Ship.iss
#include core/obj_CommandQueue.iss



function atexit()
{

}

function main()
{
	echo "${Time} ComBot: Starting"

	declarevariable UI obj_ComBotUI script
	declarevariable ComBot obj_ComBot script

	declarevariable Game obj_Game script
	declarevariable Move obj_Move script
	declarevariable Ship obj_Ship script
	declarevariable CommandQueue obj_CommandQueue script

	UI:Update["ComBot", "Module initialization complete", "y"]
	
	variable index:item Cargo
	while TRUE
	{
		MyShip:GetCargo[Cargo]
		echo ${Cargo.Used}
		wait 10
	}
}
