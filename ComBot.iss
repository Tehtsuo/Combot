#if ${ISXEVE(exists)}
#else
	#error Combot requires ISXEVE to be loaded before running
#endif



function atexit()
{

}

function main()
{
	echo "${Time} Combot: Starting"

	while TRUE
	{
		wait 10
	}
}
