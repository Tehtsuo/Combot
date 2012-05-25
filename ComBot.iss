#if ${ISXEVE(exists)}
#else
	#error ComBot requires ISXEVE to be loaded before running
#endif


#include core/obj_Warp.iss
#include core/obj_CommandQueue.iss



function atexit()
{

}

function main()
{
	echo "${Time} ComBot: Starting"

	declarevariable Warp obj_Warp script
	declarevariable CommandQueue obj_CommandQueue script
	
	
	while TRUE
	{
		wait 10
	}
}
