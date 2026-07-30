/* Common main.c for the benchmarks

 Copyright (C) 2014 Embecosm Limited and University of Bristol
 Copyright (C) 2018-2019 Embecosm Limited

 Contributor: James Pallister <james.pallister@bristol.ac.uk>
 Contributor: Jeremy Bennett <jeremy.bennett@embecosm.com>

 This file is part of Embench and was formerly part of the Bristol/Embecosm
 Embedded Benchmark Suite.

 SPDX-License-Identifier: GPL-3.0-or-later */

#include "support.h"

/*--------------------------------------------------------------*/
/* main function										        */
/*--------------------------------------------------------------*/
int main()
{
	volatile int result;
	int verify = 0;
	int ret = 0;

	while (1)
	{

		result = benchmark();

		/* bmarks that use arrays will check a global array rather than int result */
		verify = verify_benchmark(result);

		if (verify != 1)
		{
			//Verify failed, hence exiting the loop
			ret = 1;
			break;
		}
	}
	return ret;
}
