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
#include core/obj_Salvage.iss
#include core/obj_Targets.iss


function atexit()
{

}

function main()
{
	echo "${Time} ComBot: Starting"

	declarevariable ComBot obj_ComBot script
	declarevariable UI obj_ComBotUI script
	declarevariable BaseConfig obj_Configuration_BaseConfig script

	declarevariable Config obj_Configuration script
	declarevariable Client obj_Client script
	declarevariable Move obj_Move script
	declarevariable InstaWarp obj_InstaWarp script
	declarevariable Ship obj_Ship script
	declarevariable Salvager obj_Salvage script
	declarevariable Targets obj_Targets script

	UI:Update["ComBot", "Module initialization complete", "y"]
	
	variable index:item Cargo
	while TRUE
	{
		wait 10
	}
}
