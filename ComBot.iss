#if ${ISXEVE(exists)}
#else
	#error ComBot requires ISXEVE to be loaded before running
#endif

#include core/Defines.iss
#include core/obj_ComBot.iss
#include core/obj_Configuration.iss

#include core/obj_State.iss
#include core/obj_ComBotUI.iss
#include core/obj_Client.iss
#include core/obj_Move.iss
#include core/obj_Module.iss
#include core/obj_ModuleList.iss
#include core/obj_Ship.iss
#include core/obj_Cargo.iss
#include core/obj_Salvage.iss
#include core/obj_Targets.iss
#include core/obj_Asteroids.iss
#include core/obj_Miner.iss
#include core/obj_HangerSale.iss


function atexit()
{

}

function main()
{
	echo "${Time} ComBot: Starting"

	declarevariable UI obj_ComBotUI script
	declarevariable ComBot obj_ComBot script
	declarevariable BaseConfig obj_Configuration_BaseConfig script
	declarevariable Config obj_Configuration script
	UI:Reload
	
	declarevariable Client obj_Client script
	declarevariable Move obj_Move script
	declarevariable InstaWarp obj_InstaWarp script
	declarevariable Ship obj_Ship script
	declarevariable Cargo obj_Cargo script
	declarevariable Salvager obj_Salvage script
	declarevariable Targets obj_Targets script
	declarevariable Asteroids obj_Asteroids script
	declarevariable Miner obj_Miner script
	declarevariable HangerSale obj_HangerSale script
	declarevariable RefineData obj_Configuration_RefineData script

	UI:Update["ComBot", "Module initialization complete", "y"]
	
	if ${Config.Common.AutoStart}
	{
		ComBot.Paused:Set[FALSE]
		${Config.Common.ComBot_Mode}:Start
	}
	else
	{
		UI:Update["ComBot", "Paused", "r"]
	}
	

	while TRUE
	{
		wait 10
	}
}
