/*
 * See Licensing and Copyright notice in naev.h
 */
#pragma once

#include "player.h"

void pfleet_update (void);
int pfleet_deploy( PlayerShip_t *ps, int deploy );
void pfleet_cargoRedistribute( PlayerShip_t *ignore );
int pfleet_cargoUsed (void);
int pfleet_cargoFree (void);
int pfleet_cargoOwned( const Commodity *com );
int pfleet_cargoAdd( const Commodity *com, int q );
int pfleet_cargoRm( const Commodity *com, int q );
