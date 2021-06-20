pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
  clock=0
  music(6)
  
  directions=
    {
      normalize({x=0,y=-1.5}), --up
      normalize({x=1,y=-1}), --up/right
      normalize({x=1.5,y=0}), --right
      normalize({x=1,y=1}), --down/right
      normalize({x=0,y=1.5}), --down
      normalize({x=-1,y=1}), --down/right
      normalize({x=-1.5,y=0}), --right
      normalize({x=-1,y=-1}) --up/right
    }

  asteroid_palette=
  {
    {1,1},
    {5,5},
    {13,13},
    {2,2},
    {4,4},
    {7,7},
    {6,6}
  }

  wave=1
  current_wave=0
  timer=0

  STATE_BEFORE_WAVE=1
  STATE_DURING_WAVE=2
  STATE_WAVE_COMPLETED=3
  STATE_WARP=4
  STATE_GAME_OVER=5

  TEXT_TYPE_POPUP=1
  TEXT_TYPE_SIGNAL=2

  ASTEROID=1
  SHIP=2

  UPGRADE_MAX_LIFE=1
  UPGRADE_MAX_ENERGY=2
  UPGRADE_MAX_SPEED=3

  WEAPON_CANNON=4
  WEAPON_LASER=5
  WEAPON_PLASMA=6

  POWERUP_BOOST=1

  upgrades=
  {
    0,--max life
    0,--max energy
    0,--max speed
    1,--cannon
    0,--laser
    0,--plasma
  }

  current_state=STATE_BEFORE_WAVE

  BUTTON_LEAVE=1
  hud =
  {
    energy =
    {
      start_x=117,
      start_y=120
    }
  }

  available_upgrades =
    {
      {
        name="+LIFE",
        base_price=500,
        locked=true,
        spr={start=176,steps=2,frame=0,flip_x=false,flip_y=false,scale=1.2,size_x=1,size_y=1},
        mov={df=3},
        type=UPGRADE_MAX_LIFE
      },
      {
        name="+POWER",
        base_price=500,
        locked=true,
        spr={start=178,steps=2,frame=0,flip_x=false,flip_y=false,scale=1.2,size_x=1,size_y=1},
        mov={df=3},
        type=UPGRADE_MAX_ENERGY
      },
      {
        name="+SPEED",
        base_price=500,
        locked=true,
        spr={start=186,steps=4,frame=0,flip_x=false,flip_y=false,scale=1.2,size_x=1,size_y=1},
        mov={df=2},
        type=UPGRADE_MAX_SPEED
      }
    }

  special_offers=
  {
    {
      name="CANNON",
      base_price=1000,
      locked=true,
      spr={start=80,steps=15,frame=0,flip_x=false,flip_y=false,scale=3,size_x=1,size_y=1},
      mov={df=3},
      type=WEAPON_CANNON
    },
    {
      name="LASER",
      base_price=1000,
      locked=true,
      spr={start=180,steps=6,frame=0,flip_x=false,flip_y=false,scale=2,size_x=1,size_y=1},
      mov={df=2},
      type=WEAPON_LASER
    },
    {
      name="PLASMA",
      base_price=1000,
      locked=true,
      spr={start=136,steps=4,frame=0,flip_x=false,flip_y=false,scale=1.5,size_x=1,size_y=1},
      mov={df=3},
      type=WEAPON_PLASMA
    }
  }
  
  offers={}
  
  credits=500

  buttons =
  {
    {
      text="leave",
      hover=false,
      disabled=false,
      rect={x1=80,y1=80,x2=102,y2=90},
      click=function (self)
        current_state=STATE_WARP
        music(-1,1000)
        texts={}
        timer=100
      end
    },
    {
      text=" buy ",
      hover=false,
      disabled=false,
      rect={x1=20,y1=62,x2=42,y2=72},
      click=function (self)
        buy(self, 1)
      end
    },
    {
      text=" buy ",
      hover=false,
      disabled=false,
      rect={x1=50,y1=62,x2=72,y2=72},
      click=function (self)
        buy(self, 2)
      end
    },
    {
      text=" buy ",
      hover=false,
      disabled=false,
      rect={x1=80,y1=62,x2=102,y2=72},
      click=function (self)
        buy(self, 3)
      end
    },
    {
      text="repair:500\136",
      hover=false,
      disabled=false,
      rect={x1=20,y1=80,x2=72,y2=90},
      click=function (self)
        if(not(self.disabled) and credits>=500) then
          ship.health=ship.max_health
          credits-=500
          self.disabled=true
        end
      end
    }
  }

  boost_powerup={
    in_use=false,
    type=POWERUP_BOOST,
    pswap={{12,8},{7,9}},
    pos={x=hud.energy.start_x+4,y=hud.energy.start_y+4},
    mov={df=1,dx=0,dy=0},
    spr={frame=0, start=124, steps=4, size_x=1,size_y=1, flip_x=false, flip_y=false, played=false,scale=1},
    locked=true}

  powerup=boost_powerup

  update_offers()
  
  ennemies_to_spawn=1

  pointer.init()
  asteroids={}
  ship=make_ship(100)
  ship.weapon=WEAPON_CANNON

  warp_started=false

  ennemies={}
  ships={}
  loots={}
  texts={}
  add(ships, ship)
  
  star_layers=
  {
    {
      sprite_x=0,
      sprite_y=0,
      pos={x=0;y=0}
    },
    {
      sprite_x=8,
      sprite_y=0,
      pos={x=0;y=0}
    },
    {
      sprite_x=16,
      sprite_y=0,
      pos={x=0;y=0}
    }
  }

  add(asteroids, make_asteroid())
  global_x=0
  global_y=0
  screenshake=0
  effects={}

  health_colors =
  {
    {2,2,2,2,2,7},--0%,
    {8,8,8,8,8,9},--25%,
    {10,10,10,10,10,9},--50%,
    {3,3,3,3,11,11,11},--75%,
    {3,3,3,3,3,3,11},--100%,
  }

end

function update_offers()
      local arr=({{1,2},{2,1},{1,3},{3,1},{3,2},{2,3}})[flr(rnd(6)+1)]
      offers={}
      local offer={}
      for i=1,3 do

        if(i==3) do
          offer=special_offers[flr(rnd(#special_offers)+1)]
        else
          offer=available_upgrades[arr[i]]
        end

        offer.pos={x=30*i,y=42}
        offer.price=offer.base_price+200*upgrades[offer.type]
        
        add(offers, offer)
      end

      for btn in all(buttons) do
        btn.disabled=false
      end
    end 

function buy(button, index)
  if(not(button.disabled) and credits >= offers[index].price) then
    button.disabled=true
    credits-=offers[index].price
    if(index==3) then
      ship.weapon=offers[index].type
      upgrades[ship.weapon]+=1
    else
      upgrades[offers[index].type]+=1
      ship.max_health=ship.max_health+10*(upgrades[UPGRADE_MAX_LIFE])
      ship.health=ship.health+10*(upgrades[UPGRADE_MAX_LIFE])
      ship.max_energy=ship.max_energy+10*(upgrades[UPGRADE_MAX_ENERGY])
      ship.current_energy=ship.max_energy
      ship.max_speed=ship.max_speed+upgrades[UPGRADE_MAX_SPEED]/4
    end
  end
end

function make_ennemy(scale)
  local ennemy=make_ship(50)

  ennemy.spr.scale=scale
  ennemy.health=(ennemy.health + 10*current_wave)*scale
  ennemy.max_speed/=scale
  ennemy.inertia_speed_factor*=scale
  ennemy.weapon=3+flr(rnd(2))+1
  ennemy.pswap={{11,8},{3,9}}
  ennemy.pos=get_edge_position()
  return ennemy
end

function hcenter(text)
  return 64-#text*2
end

function _update()
  clock=(clock+1)%100
  timer=max(0, timer-1)

  pointer.update()
    
  for offer in all(available_upgrades) do
    update(offer)
  end
  
  for offer in all(special_offers) do
    update(offer)
  end

  if(ship.health<=0 and current_state != STATE_GAME_OVER) then
    del(ships, ship)
    current_state=STATE_GAME_OVER
    texts={}
  end

  if(current_state==STATE_GAME_OVER) then
    if(#texts==0 and timer==0) then
    
      add(texts,make_text("game over", {x=64-#"game over"*2, y=10}, -1, TEXT_TYPE_SIGNAL, 12))
      timer=50
    elseif(#texts==1 and timer==0) then
      add(texts,make_text("another will replace you", {x=64-#"another will replace you"*2, y=20}, -1, TEXT_TYPE_SIGNAL))
      timer=100
    elseif(#texts==2 and timer==0) then
      add(texts,make_text("score", {x=10, y=50}, -1, TEXT_TYPE_SIGNAL))
      timer=50
    elseif(#texts==3 and timer==0) then
      add(texts,make_text("asteroids:         "..ship.kills.asteroids, {x=10, y=65}, -1, TEXT_TYPE_SIGNAL, 4))
      timer=30
    elseif(#texts==4 and timer==0) then
      add(texts,make_text("pirates  :         "..ship.kills.ships, {x=10, y=75}, -1, TEXT_TYPE_SIGNAL, 8))
      timer=30
    elseif(#texts==5 and timer==0) then
      add(texts,make_text("credits  :         "..credits, {x=10, y=85}, -1, TEXT_TYPE_SIGNAL, 10))
      timer=30
    elseif(#texts==6 and timer==0) then
      add(texts,make_text("total    :         "..(credits*2+100*ship.kills.asteroids+1000*ship.kills.ships), {x=10, y=95}, -1, TEXT_TYPE_SIGNAL))
      timer=30
    elseif(#texts==7 and timer==0) then
      add(texts,make_text("press x to be replaced", {x=64-#"press x to be replaced"*2, y=110}, -1, TEXT_TYPE_SIGNAL))
    elseif(btn(5) and #texts==8) then
      _init()
    end
  elseif(current_state==STATE_BEFORE_WAVE) then
      if(#texts==0) then
        add(texts,make_text(">try shooting some asteroids,", {x=0, y=0}, -1, TEXT_TYPE_SIGNAL))
        add(texts,make_text("hunter...", {x=0, y=6}, -1, TEXT_TYPE_SIGNAL))

          if(wave==1) then
            add(texts,make_text("aim with mouse", {x=50, y=83}, -1, TEXT_TYPE_SIGNAL,8))
            add(texts,make_text("left click shoot", {x=50, y=93}, -1, TEXT_TYPE_SIGNAL,9))
            add(texts,make_text("right click boost", {x=50, y=103}, -1, TEXT_TYPE_SIGNAL,10))
            add(texts,make_text("arrows to thrust", {x=50, y=113}, -1, TEXT_TYPE_SIGNAL,11))
          end
      end

      if(ship.kills.current_wave_asteroids>=ship.kills.current_wave_asteroids_before_spawn and #ennemies==0) then
        current_wave=wave
        current_state=STATE_DURING_WAVE
        music(0)
        timer=rnd(200)+100
        texts={}
      end
  elseif(current_state==STATE_DURING_WAVE) then
    if(#texts==0 and #ennemies==0 and timer!=0) then
      add(texts,make_text(">looks like there are pirates", {x=0, y=0}, -1, TEXT_TYPE_SIGNAL,8))
      add(texts,make_text("around!", {x=0, y=6}, -1, TEXT_TYPE_SIGNAL,8))
    end

    if(#ennemies==0 and timer==0) then
      texts={}
      if(wave==current_wave) then
        for i=1,wave do
          local ennemy=make_ennemy(0.8+i/10)
          add(ships, ennemy)
          add(ennemies, ennemy)
        end
        wave+=1
      elseif(#loots==0) then
        current_state=STATE_WAVE_COMPLETED
        ship.mov.dx=0
        ship.mov.dy=0
        music(6)
        ship.kills.current_wave_asteroids=0
        ship.kills.current_wave_asteroids_before_spawn=flr(rnd(10))+5
        update_offers()
      end
    end
  elseif(current_state==STATE_WAVE_COMPLETED) then
    ship.shots={}
    ship.mov.dx=0
    ship.mov.dy=0

    if(#texts==0) then
      add(texts,make_text(">thank you for securing the", {x=0, y=0}, -1, TEXT_TYPE_SIGNAL,12))
      add(texts,make_text("system. do you want to buy?", {x=0, y=6}, -1, TEXT_TYPE_SIGNAL,12))
    end

    for button in all(buttons) do
        button.hover=not(button.disabled) and is_mouse_over(button.rect)
        if(button.hover and pointer.pressed_left()) then
          button.click(button)
        end
    end
  elseif(current_state==STATE_WARP) then
    if(warp_started==false) then
      add(texts,make_text(">time to leave this place...", {x=0, y=0}, 100, TEXT_TYPE_SIGNAL,10))

      if(timer==0) then
        warp_started=true
        ship.mov.dx=directions[ship.spr.frame+1].x*75
        ship.mov.dy=directions[ship.spr.frame+1].y*75
        screenshake=200

        for swap in all(asteroid_palette) do
          swap[2]=swap[2]+wave%16
          if(swap[2]==0) swap[2]=1+flr(rnd(15))
        end
        timer=100
      elseif(timer==70) then
        music(3,300)
      else
        add(effects, make_effect({x=rnd(128),y=rnd(128)}, 114, 3, 1, rnd((100-timer)/10),pswap))
      end

    elseif(timer == 0) then
      current_state=STATE_BEFORE_WAVE
      warp_started=false
      music(-1)
      music(6,1000)
    else
      pswap={{12,clock%16},{7,clock%16}}
      add(effects, make_effect({x=64,y=64}, 119, 4, 1, 5, pswap))

      add(effects, make_effect({x=rnd(128),y=rnd(128)}, 119, 4, 1, rnd(5),pswap))
      add(effects, make_effect({x=rnd(128),y=rnd(128)}, 119, 4, 1, rnd(5),pswap))
      add(effects, make_effect({x=rnd(128),y=rnd(128)}, 119, 4, 1, rnd(5),pswap))
      add(effects, make_effect({x=rnd(128),y=rnd(128)}, 119, 4, 1, rnd(5),pswap))

      local particle_1 = make_effect({x=rnd(128),y=rnd(128)}, 114, 3, 1, rnd(5),pswap)
      particle_1.locked=true
      add(effects, particle_1)

      if(ship.mov.dx>0) ship.mov.dx=max(0,ship.mov.dx-0.75)
      if(ship.mov.dx<0) ship.mov.dx=min(0,ship.mov.dx+0.75)
      if(ship.mov.dy>0) ship.mov.dy=max(0,ship.mov.dy-0.75)
      if(ship.mov.dy<0) ship.mov.dy=min(0,ship.mov.dy+0.75)
    end
  end

  for effect in all(effects) do
    update(effect)
    if(effect.spr.played) then
      del(effects, effect)
    end
  end

  for text in all(texts) do
    if (text.type==TEXT_TYPE_POPUP) then
      text.pos.y-=1
    elseif (text.type==TEXT_TYPE_SIGNAL) then
      if (not(text.played)) then
        text.content=sub(text.signal, 0, text.current)
        text.current+=1
        if(#text.content==#text.signal) text.played=true
      end
    end
    
    if(text.ttl!=-1) then
      text.ttl-=1
      if(text.ttl==0) del(texts,text)
    end
  end

  if(current_state != STATE_WARP) then
    if(#asteroids<10 and rnd(100)>90) then
      add(asteroids, make_asteroid())
    end
  end

  for ast in all(asteroids) do
    update(ast)
    if(ast.pos.x>256 or ast.pos.y>256 or ast.pos.x<-128 or ast.pos.y<-128) then
      del(asteroids, ast)
    end
  end

  update(powerup)

  if(current_state==STATE_BEFORE_WAVE or current_state==STATE_DURING_WAVE or current_state==STATE_GAME_OVER) then
    
    ship.spr.frame=get_direction_towards(pointer, ship)
    ship.centers=get_centers(ship)

    if(ship.health>0) then
      local moved=false
      if(btn(2)) then
        moved=true
        ship.mov.dx=ship.mov.dx+(0.1*directions[ship.spr.frame+1][1]*ship.inertia_speed_factor)
        ship.mov.dy=ship.mov.dy+(0.1*directions[ship.spr.frame+1][2]*ship.inertia_speed_factor)
      end
      if(btn(0)) then
        moved=true
        ship.mov.dx=ship.mov.dx+(0.1*directions[(ship.spr.frame-2)%8+1][1]*ship.inertia_speed_factor)
        ship.mov.dy=ship.mov.dy+(0.1*directions[(ship.spr.frame-2)%8+1][2]*ship.inertia_speed_factor)
      end
      if(btn(1)) then
        moved=true
        ship.mov.dx=ship.mov.dx+(0.1*directions[(ship.spr.frame+2)%8+1][1]*ship.inertia_speed_factor)
        ship.mov.dy=ship.mov.dy+(0.1*directions[(ship.spr.frame+2)%8+1][2]*ship.inertia_speed_factor)
      end
      if(btn(3)) then
        moved=true
        ship.mov.dx=ship.mov.dx+(0.1*directions[(ship.spr.frame+4)%8+1][1]*ship.inertia_speed_factor)
        ship.mov.dy=ship.mov.dy+(0.1*directions[(ship.spr.frame+4)%8+1][2]*ship.inertia_speed_factor)
      end

      if(moved) then
        local pswap=nil
        if(powerup!=nil and powerup.in_use) pswap=powerup.pswap
        add(effects, make_effect({x=ship.pos.x-ship.mov.dx*2,y=ship.pos.y-ship.mov.dy*2}, 119, 4, 1, rnd(1)+0.5,pswap))
      end

      if(pointer.pressed_left() and ship.last_shot<0 and ship.current_shots < ship.max_consecutive_shots) then
        shoot(ship)
        ship.shot_decay=ship.min_shot_decay
      else
        ship.shot_decay+=ship.shot_decay_increment
        ship.current_shots=max(0,ship.current_shots-ship.shot_decay)
        ship.last_shot-=1
      end

      if(powerup!=nil and pointer.pressed_right() and ship.current_energy>0 and not(ship.energy_depleted)) then
        ship.energy_gain=ship.min_energy_gain
        ship.current_energy=max(0,ship.current_energy-ship.energy_consumption)
        start_powerup()
      else
        ship.energy_depleted=ship.current_energy <= 0 or (ship.energy_depleted and ship.current_energy < 50)
        if(ship.energy_depleted and clock%3==0) sfx(11,1)
        ship.energy_gain+=ship.energy_gain_increment
        ship.current_energy=min(ship.max_energy, ship.current_energy+ship.energy_gain)
        stop_powerup()
      end
    end

    for sh in all(ships) do
      if(sh.mov.dx>0) sh.mov.dx=max(0,sh.mov.dx-(1/sh.inertia_speed_factor/100))
      if(sh.mov.dx<0) sh.mov.dx=min(0,sh.mov.dx+(1/sh.inertia_speed_factor/100))
      if(sh.mov.dy>0) sh.mov.dy=max(0,sh.mov.dy-(1/sh.inertia_speed_factor/100))
      if(sh.mov.dy<0) sh.mov.dy=min(0,sh.mov.dy+(1/sh.inertia_speed_factor/100))

      if(sh.mov.dx>sh.max_speed) sh.mov.dx=sh.max_speed
      if(sh.mov.dy>sh.max_speed) sh.mov.dy=sh.max_speed
      if(sh.mov.dx<-1*sh.max_speed) sh.mov.dx=-1*sh.max_speed
      if(sh.mov.dy<-1*sh.max_speed) sh.mov.dy=-1*sh.max_speed

      for laser in all(sh.lasers) do
        if(laser.ttl==0) then
          del(sh.lasers,laser)
        else
          laser.ttl-=1
          if(laser.target.hit != nil) do
            local hit=laser.target.hit
            hit.health-=laser.damage+laser.damage_mult
            
            add(texts,make_text(laser.damage+laser.damage_mult, hit.pos, 20, TEXT_TYPE_POPUP))

            if(hit.destroyed==false and hit.health <= 0) then
              hit.destroyed=true
              
              if(hit.type==ASTEROID) then
                if(sh==ship) screenshake=106

                if(rnd(100)>50) add(loots, make_loot(hit.pos))

                sh.kills.asteroids+=1
                sh.kills.current_wave_asteroids+=1
                add(effects, make_effect(hit.pos, 107, 7, 1, hit.spr.scale))
                del(asteroids, hit)
              elseif(hit.type==SHIP and hit!=sh and (hit==ship or sh==ship)) then
                  add(effects, make_effect(hit.pos, 144, 7, 2, 2.5))
                  for i=0,rnd(5) do
                    add(loots, make_loot({x=hit.pos.x+rnd(10)-5,y=hit.pos.y+rnd(10)-5}, 1))
                  end
                  del(ennemies, hit)
                  del(ships, hit)
                  if(hit!=ship) then
                    if (#texts==0) then
                      add(texts,make_text(">nice shot!", {x=0, y=0}, 50, TEXT_TYPE_SIGNAL))
                    end
                    sh.kills.ships+=1
                  end
              end
            else
              if(#effects<20) add(effects, make_effect(laser.target, 102, 4, 1, laser.target.hit.spr.scale))
                
              laser.target.hit.mov.dx+=(laser.target.x-laser.start.x)/10000
              laser.target.hit.mov.dy+=(laser.target.y-laser.start.y)/10000
            end
          end
        end
      end

      for shot in all(sh.shots) do
        update(shot)
        if(shot.pos.x>256 or shot.pos.y>256 or shot.pos.x<-128 or shot.pos.y<-128) then
          del(sh.shots, shot)
        else

          for other in all(ships) do
            if(sh != other and (sh==ship or other==ship)) do
              if(is_collision(shot,other)) then
                add(effects, make_effect(other.pos, 107, 7, 1, 1))
                screenshake=106
                other.health=max(0,other.health-shot.damage)
                add(texts,make_text(shot.damage, other.pos, 20, TEXT_TYPE_POPUP))
                if(other.health==0) then
                  add(effects, make_effect(other.pos, 144, 7, 2, 2.5))
                  for i=0,rnd(5) do
                    add(loots, make_loot({x=other.pos.x+rnd(10)-5,y=other.pos.y+rnd(10)-5}, 1))
                  end
                  del(ships, other)
                  if(other!=ship) then
                    del(ennemies, other)
                    add(texts,make_text(">nice shot!", {x=0, y=0}, 50, TEXT_TYPE_SIGNAL))
                    sh.kills.ships+=1
                  end
                else
                  sfx(12,1)
                  other.mov.dx=(other.mov.dx+shot.mov.dx/4)
                  other.mov.dy=(other.mov.dy+shot.mov.dy/4)
                end
                del(sh.shots, shot)
                break
              end
            end
          end
        end
      end

      for ast in all(asteroids) do
        if(is_collision(ast,sh)) do
          sh.health-=0.1
          add(effects, make_effect(sh.pos, 102, 4, 1, 1))
          if(sh==ship) then
            screenshake=106
            sfx(12)
          end
        end
        for shot in all(sh.shots) do
          if(is_collision(shot, ast)) then
            ast.health-=shot.damage
            add(texts,make_text(shot.damage, ast.pos, 20, TEXT_TYPE_POPUP))
            if(ast.health<=0) then
              if(sh==ship) then
                screenshake=106
                sfx(12)
              end

              if(rnd(100)>50) add(loots, make_loot(ast.pos, 1))

              sh.kills.asteroids+=1
              sh.kills.current_wave_asteroids+=1
              add(effects, make_effect(ast.pos, 107, 7, 1, ast.spr.scale))
              del(asteroids, ast)
            else
              add(effects, make_effect(shot.pos, 102, 4, 1, 1))
              ast.mov.dx=(ast.mov.dx+shot.mov.dx/4)/2
              ast.mov.dy=(ast.mov.dy+shot.mov.dy/4)/2
              ast.mov.df+=1
              ast.spr.flip_x=rnd(2)>1
              ast.spr.flip_y=rnd(2)>1
            end
            del(sh.shots, shot)
          end
        end
      end

      sh.health=max(0, sh.health)
    end
  end

  for loot in all(loots) do
    loot.ttl-=1
    if(loot.ttl < 0) then
      add(effects, make_effect(loot.pos, 107, 7, 1,rnd(1)+0.5))
      del(loots, loot)
    else
      if(loot.ttl < 100 and clock%5==0) do
        add(effects, make_effect(loot.pos, 114, 3, 1,rnd(1)+0.5))
      end
      update(loot)
      if(is_collision(loot,ship)) do
        add(effects, make_effect(loot.pos, 114, 3, 1, 2))
        
        sfx(14,1)
        credits+=loot.value
        add(texts,make_text(loot.value.."\136", loot.pos, 20, TEXT_TYPE_POPUP))
        del(loots, loot)
      end
    end
  end

  global_x=-1*ship.mov.dx
  global_y=-1*ship.mov.dy

  for i=1,#star_layers do
    star_layers[i].pos.x+=global_x*2/i
    star_layers[i].pos.y+=global_y*2/i
  end

  for ennemy in all(ennemies) do
    update_other_ship(ennemy)
  end
end

function start_powerup()
    local direction=directions[ship.spr.frame+1]
    
    add(effects, make_effect({x=ship.pos.x-ship.mov.dx*2,y=ship.pos.y-ship.mov.dy*2}, 119, 4, 1, rnd(1)+0.5,powerup.pswap))
    ship.mov.dx=(direction[1])*200
    ship.mov.dy=(direction[2])*200

    if(powerup.in_use==false) powerup.last_max_speed=ship.max_speed
    ship.max_speed=5+upgrades[UPGRADE_MAX_SPEED]/4
  powerup.in_use=true
end

function stop_powerup()
  if(powerup.in_use) then
    powerup.in_use=false
    if(powerup.type==POWERUP_BOOST and powerup.last_max_speed != nil) then
      ship.max_speed=powerup.last_max_speed
    end
  end
end

function normalize(pos1, pos2)
  if(pos2==nil) then
    pos2={x=0, y=0}
  end

  local _x = (pos1.x-pos2.x)
  local _y = (pos1.y-pos2.y)

  local distance = sqrt(_x*_x+_y*_y)
  
  return { _x / distance, _y / distance, x=_x / distance, y=_y / distance}
end

function shoot(some_ship)
  local direction=directions[some_ship.spr.frame+1]
  local damage_mult=0
  if(some_ship==ship) damage_mult=upgrades[some_ship.weapon]
  if(some_ship.weapon==WEAPON_CANNON) then
    if(some_ship==ship) then
      direction = normalize(pointer.pos, ship.pos)
    end

    sfx(7,1)

    local shot=make_shot(some_ship.pos, some_ship.spr.frame, direction)
    shot.mov.dx*=1.2
    shot.mov.dy*=1.2
    shot.delay_between_shots=0
    shot.damage=6+damage_mult
    shot.spr.scale=some_ship.spr.scale
      
    add(effects, make_effect(shot.pos, 114, 3, 1, rnd(1)+0.5))
    add(some_ship.shots, shot)
    some_ship.last_shot=shot.delay_between_shots
    ship.current_shots+=1
  elseif(some_ship.weapon==WEAPON_PLASMA) then

    sfx(9,1)
    for i=0,3 do
      for j=-1,1 do
        local index=(some_ship.spr.frame+j)%8
        direction=directions[index+1]

        local beam=make_shot(some_ship.pos, some_ship.spr.frame, direction)
        beam.pos.x+=direction[1]*i
        beam.pos.y+=direction[2]*i
        
        beam.mov.dx+=ship.mov.dx
        beam.mov.dy+=ship.mov.dy
        beam.mov.dx*=1.5
        beam.mov.dy*=1.5
        beam.spr.start=136+index%4
        beam.spr.steps=1
        beam.delay_between_shots=0
        
        beam.damage=1+damage_mult
        beam.spr.scale=some_ship.spr.scale
        add(some_ship.shots, beam)
        some_ship.last_shot=beam.delay_between_shots
      end
    end
    ship.current_shots+=0.5
  elseif(some_ship.weapon==WEAPON_LASER) then

    sfx(8,1)

    direction.x=64+rnd(30)-15
    direction.y=64+rnd(30)-15
    if(some_ship==ship) direction=pointer.pos
    add(ship.lasers, make_laser(some_ship, direction, damage_mult))
    ship.current_shots+=0.5
  end
end

function get_direction_towards(item, target)

  --     |   |
  --     |   |
  -- ----a---b----
  --     | T |
  -- ----c---d----
  --     |   |
  --     |   |

  local a={x=target.pos.x-16                  ,y=target.pos.y-16}
  local b={x=target.pos.x+16                  ,y=target.pos.y-16}
  local c={x=target.pos.x-16                  ,y=target.pos.y+16}
  local d={x=target.pos.x+16                  ,y=target.pos.y+16}

  if(item.pos.x < a.x) then
    if(item.pos.y < a.y) return 7
    if(item.pos.y < c.y) return 6
    return 5
  end

  if(item.pos.x > b.x) then
    if(item.pos.y < b.y) return 1
    if(item.pos.y < d.y) return 2
    return 3
  end

  if(item.pos.y>a.y) return 4
  
  return 0
end

function update_other_ship(other)
  if(clock%50==0) then
    other.spr.frame=get_direction_towards(ship, other)
  end

  local direction=directions[other.spr.frame+1]

  local target=ship.pos
  if (ship.health < 0) target={x=rnd(256)-128, y=rnd(256)-128}

  if(abs(other.mov.dx) < 0.05 + rnd(1)) other.mov.dx += (rnd(1)*(target.x-other.pos.x + rnd(30) - 15 )*0.1)
  if(abs(other.mov.dy) < 0.05 + rnd(1)) other.mov.dy += (rnd(1)*(target.y-other.pos.y + rnd(30) - 15 )*0.1)

  if(rnd(100)>90 and ship.health>0) then
    shoot(other)
  end

  update(other)
end

function camshake()
    local shakex=0
    local shakey=0
    if screenshake > 105 then
        shakex=3-rnd(6)
        shakey=3-rnd(6)
        screenshake -= 1
    elseif screenshake > 0 then
      screenshake -=1
    end
    camera(shakex, shakey)
end

function get_centers(drawable)

  local size_x=8*drawable.spr.size_x
  local size_y=8*drawable.spr.size_y

  local positions={}

  for i=0,drawable.spr.size_x-1 do
    for j=0, drawable.spr.size_y-1 do
      local pos={}
      local dx=drawable.pos.x-(size_x*drawable.spr.scale/2)*i
      local dy=drawable.pos.y-(size_y*drawable.spr.scale/2)*j
      pos.x=4+(dx*2+i*8)/2
      pos.y=4+(dy*2+j*8)/2
      add(positions, pos)
    end
  end

  return positions
end

function intersect(x1,y1,x2,y2,x3,y3,x4,y4)
    uA=((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1))
    uB=((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1))
    if (uA >= 0 and uA <= 1 and uB >= 0 and uB <= 1) then
        intersectionX=x1 + (uA * (x2-x1));
        intersectionY=y1 + (uA * (y2-y1));
        return {x=intersectionX, y=intersectionY}
    end
    return nil
end

function intersections(start,target,drawable)
    local x=drawable.pos.x
    local y=drawable.pos.y
    local width=2*drawable.spr.scale*drawable.spr.size_x
    local height=2*drawable.spr.scale*drawable.spr.size_y
    local results={}

    local a=intersect(start.x,start.y,target.x,target.y, x-width,   y-height,        x-width, y+height)
    local b=intersect(start.x,start.y,target.x,target.y, x+width,   y-height,        x+width, y+height)
    local c=intersect(start.x,start.y,target.x,target.y, x-width,   y-height,        x+width, y-height)
    local d=intersect(start.x,start.y,target.x,target.y, x-width,   y+height,        x+width, y+height)

    if(a != nil) add(results, a)
    if(b != nil) add(results, b)
    if(c != nil) add(results, c)
    if(d != nil) add(results, d)

    for result in all(results) do
      result.hit=drawable
    end

    return results
end

function is_mouse_over(rect)
  return pointer.pos.x > rect.x1 and pointer.pos.x < rect.x2 and pointer.pos.y > rect.y1 and pointer.pos.y < rect.y2
end

function is_collision(first,second)
  if(abs(first.pos.x-second.pos.x)>16 or abs(first.pos.y-second.pos.y)>16) then
    return false
  end

  local first_centers=first.centers
  local second_centers=second.centers

  for first_center in all(first_centers) do
    for second_center in all(second_centers) do
      local distance_x=(second_center.x-first_center.x)
      local distance_y=(second_center.y-first_center.y)

      local distance=sqrt(distance_x*distance_x+distance_y*distance_y)

      if(distance<(4*first.spr.scale+4*second.spr.scale) and distance!=0) then
        return true
      end
    end
  end

  return false
end

function make_effect(pos, start, steps, size, scale, pswap)
  return {
    spr={frame=0,start=start,steps=steps,size_x=size,size_y=size,flip_x=rnd(2)>1,flip_y=rnd(2)>1,played=false,scale=scale},
    pos={x=pos.x+rnd(10)-5, y=pos.y+rnd(10)-5},
    mov={dx=0,dy=0,df=4},

    effect_type=1,
    pswap=pswap
  }
end

function make_loot(origin)
  return {
  
  spr={
    start=128,
    steps=8,
    frame=0,
    size_x=1,
    size_y=1,
    flip_x=false,
    flip_y=false,
    played=false,
    scale=1
  },
  pos={x=origin.x,y=origin.y},
  mov= {dx=0, dy=0, df=3},

  ttl=200,

  value=flr(rnd(100))+100
  }
end

function make_laser(source, target,damage_mult)
  local laser={start=source.pos,damage_mult=damage_mult}

  local dx=(target.x-source.pos.x)*10
  local dy=(target.y-source.pos.y)*10

  local target={x=target.x+dx, y=target.y+dy}

  local hits={}
  for ast in all(asteroids) do
    if(ast.pos.x<150 and ast.pos.x>-10 and ast.pos.y<150 and ast.pos.y>-10) then
      for intersection in all(intersections(laser.start, target, ast)) do
        add(hits, intersection)
      end
    end
  end

  for sh in all(ships) do
    if(sh != source and sh.pos.x<150 and sh.pos.x>-10 and sh.pos.y<150 and sh.pos.y>-10) then
      for intersection in all(intersections(laser.start, target, sh)) do
        add(hits, intersection)
      end
    end
  end

  local closest=target
  closest.distance=1000
  for hit in all(hits) do
    local distance_x=(hit.x-source.pos.x)
    local distance_y=(hit.y-source.pos.y)

    local distance=sqrt(distance_x*distance_x+distance_y*distance_y)
    if (distance < closest.distance) then
      closest=hit
      closest.distance=distance
    end
  end


  laser.target=closest
  laser.ttl=flr((rnd(2)+2))
  laser.damage=1
  return laser
end

function make_shot(source_pos, frame, direction)
  return {
  spr=  {frame=0,
    start=80+2*frame,
    steps=2,
    size_x=1,
    size_y=1,
    flip_x=false,
    flip_y=false,
    played=false,
    scale=1},
  pos=  {x=source_pos.x+(direction[1]+(sgn(direction[1])*8))/8,
    y=source_pos.y+(direction[2]+(sgn(direction[2])*4))/4},
  mov= 
    {dx=direction[1]*4,
    dy=direction[2]*4,
    df=3},
  damage=8,
  delay_between_shots=3 }
end

function update(updatable)
  if(updatable.locked==nil or updatable.locked==false) then
    updatable.pos.x+=updatable.mov.dx+global_x
    updatable.pos.y+=updatable.mov.dy+global_y
  end
  if(updatable.mov.df!=0 and clock%updatable.mov.df==0) then
    local new_frame=(updatable.spr.frame+1)%updatable.spr.steps
    if(new_frame==0 and updatable.spr.frame!=0) updatable.spr.played=true
    updatable.spr.frame=new_frame
  end

  if(updatable.effect_type==nil and not(updatable.locked)) updatable.centers=get_centers(updatable)
end

function _draw()
  cls()

  camshake()

  for i=1,#star_layers do
    draw_stars(i)
  end

  for pswap in all(asteroid_palette) do
    pal(pswap[1], pswap[2])
  end
  for ast in all(asteroids) do
    draw(ast)
  end
  pal()

  for s in all(ships) do
    for shot in all(s.shots) do
      draw(shot)
    end
    for laser in all(s.lasers) do
      local start_offset1=flr(rnd(4)-2)
      local end_offset1=flr(rnd(4)-2)
      local start_offset2=flr(rnd(4)-2)
      local end_offset2=flr(rnd(4)-2)
      line(laser.start.x-start_offset1, laser.start.y-start_offset1, laser.target.x-end_offset1, laser.target.y-end_offset1, clock%16)
      line(laser.start.x, laser.start.y, laser.target.x, laser.target.y, clock%16)
      line(laser.start.x-start_offset2, laser.start.y-start_offset2, laser.target.x-end_offset2, laser.target.y-end_offset2, clock%16)
    end
    if (s.pswap!=nil) do
      for pswap in all(s.pswap) do
        pal(pswap[1], pswap[2])
      end
    end
    draw(s)
    pal()
  end

  for loot in all(loots) do
    draw(loot)
  end

  for effect in all(effects) do
    if(effect.pswap!=nil) then
      for pswap in all(effect.pswap) do
        pal(pswap[1], pswap[2])
      end
    end

    draw(effect)
    pal()
  end

  for text in all(texts) do
    local color=text.color
    if(text.type==TEXT_TYPE_POPUP) color=(clock+flr(rnd(15)))%15
    print(text.content, text.pos.x, text.pos.y, color)
  end

  pal()
  draw_hud()
end

function draw_hud()
  if(current_state!=STATE_GAME_OVER) then
    if(current_state==STATE_WAVE_COMPLETED) then
      draw_hud_shop()
    end

    rectfill(118, 0, 127,127,0)
    draw_hud_health()
    draw_hud_energy()
    draw_hud_shots()

    for i=1,3 do
      for j=1, upgrades[i] do
        draw({spr=available_upgrades[i].spr,pos={x=j*9-5,y=87+i*10}},0.9)
      end
    end

    print("credits:"..credits.."\136", 0, 123,6)

    pointer.draw()
  end
end

function draw_hud_shop()

  for button in all(buttons) do
    if(not(button.disabled)) then
      local bg=0
      local fg=7
      if(button.hover) then
        bg=9
        fg=5
      end
      rect(button.rect.x1,button.rect.y1,button.rect.x2,button.rect.y2,fg)
      rectfill(button.rect.x1+1,button.rect.y1+1,button.rect.x2-1,button.rect.y2-1,bg)
      print(button.text, button.rect.x1+2, button.rect.y1+3,fg)
    end
  end

  for offer in all(offers) do
      print(offer.name,offer.pos.x-4-#offer.name,offer.pos.y-16,1+clock%15)
      draw(offer)
      print(offer.price.."\136",offer.pos.x-8,offer.pos.y+12,10)
  end
end

function draw_hud_health()

  local health_ratio=ship.health/ship.max_health
  local c=health_colors[flr(health_ratio*(#health_colors-1))+1]

  for i=117,127 do
    if (i%2==0) line(i,0,i,35,5 )
  end
  for i=117,127 do
    local dy=i/(127-117)
    line(i,
         35,
         i,
         35-ship.health*34/ship.max_health-cos(dy-(dy/2)+clock/10)*(max(screenshake,50))/100,
         c[flr(rnd(#c))+1])
  end
end

function draw_hud_energy()
  local ratio=83/ship.max_energy
  local higher_ratio=90/ship.max_energy
  local start_x=hud.energy.start_x
  local start_y=hud.energy.start_y

  local background_color=5
  if(ship.energy_depleted) background_color=(5+clock/1.5)%15

  rectfill(start_x,start_y-2,start_x+1,start_y-83,background_color)
  rectfill(start_x,start_y-2,start_x+3,start_y-0.75*83+8,background_color)
  rectfill(start_x,start_y-2,start_x+5,start_y-0.5*83+8,background_color)
  rectfill(start_x,start_y-2,start_x+7,start_y-0.25*83+8,background_color)

  if(powerup!=nil) then
    local powerup_color=5
    if(powerup.in_use) powerup_color=clock%16
    rectfill(start_x,start_y,start_x+7,start_y+7,powerup_color)

    draw(powerup)
  end
  for i=1,8 do
    local dy=i/5
    local z=ratio
    local y=83
    if(i>6) then
      z=higher_ratio
      y+=7
    end

    local height=min(y*(0.25*flr((i+1)/2)),ship.current_energy*z)

    line(
      start_x-i+8,
      start_y-2,
      start_x-i+8,
      min(start_y-2,start_y-height+8)
      -cos(dy-(dy/2)+clock/10)*(max(screenshake,50))/100
    , ({7,12,13,1})[1+flr((i-1)/2)])
  end
end

function draw_hud_shots()
  local ratio=83/ship.max_consecutive_shots
  local max_height=ship.max_consecutive_shots*ratio
  local start_x=127
  local start_y=127

  rectfill(start_x,start_y,start_x-1,start_y-83+2,5)
  rectfill(start_x-2,start_y-0.25*83-1,start_x-3,start_y-83+2,5)
  rectfill(start_x-4,start_y-0.5*83-1,start_x-5,start_y-83+2,5)
  rectfill(start_x-6,start_y-0.75*83-1,start_x-7,start_y-83+2,5)

  rectfill(start_x,start_y-max_height,start_x-7,start_y-max_height-7,5)

  local current_height=min(max_height,ship.current_shots*ratio-7.5)

  local colors={7,10,9,8}

  rectfill(start_x,start_y-max_height,start_x-7,start_y-max_height+1-(upgrades[ship.weapon]%7),(upgrades[ship.weapon]/7)+clock%2)
  draw({spr=special_offers[ship.weapon-3].spr, pos={x=start_x-2,y=start_y-max_height-2}},0.8)

  for i=1,8 do
    local dy=i/5
    local limit=(flr((i-1)/2)*0.25*83)+3
    if(current_height > limit) then
      line(
        start_x-i+1,
        start_y-8+10-limit,
        start_x-i+1,
        max(start_y-8+10-max_height,start_y-8+10-current_height
        -cos(dy-(dy/2)+clock/10)*(max(screenshake,50))/100),
      
        colors[1+flr((i-1)/2)])
    end
  end
end

function draw_stars(layer)
  local x=star_layers[layer].pos.x%64
  local y=star_layers[layer].pos.y%64

  local a=star_layers[layer].sprite_x
  local b=star_layers[layer].sprite_y

  -- 2  1  12 11
  -- 3  A  D  10
  -- 4  B  C  9
  -- 5  6  7  8

  map(a,b,x      ,y-64   ,8,8) --1
  map(a,b,x-64   ,y-64   ,8,8) --2
  map(a,b,x-64   ,y      ,8,8) --3
  map(a,b,x      ,y      ,8,8) --A

  map(a,b,x-64   ,y+64   ,8,8) --4
  map(a,b,x-64   ,y+64+64,8,8) --5
  map(a,b,x      ,y+64+64,8,8) --6
  map(a,b,x      ,y+64   ,8,8) --B

  map(a,b,x+64   ,y+64+64,8,8) --7
  map(a,b,x+64+64,y+64+64,8,8) --8
  map(a,b,x+64+64,y+64   ,8,8) --9
  map(a,b,x+64   ,y+64   ,8,8) --C

  map(a,b,x+64+64,y      ,8,8) --10
  map(a,b,x+64+64,y-64   ,8,8) --11
  map(a,b,x+64   ,y-64   ,8,8) --12
  map(a,b,x+64   ,y      ,8,8) --D
end

function draw(drawable, scale)
  local base=drawable.spr.frame*drawable.spr.size_x
  local sprite=drawable.spr.start+flr(base/16)*(16*(drawable.spr.size_y-1))+base

  local size_x=8*drawable.spr.size_x
  local size_y=8*drawable.spr.size_y

  if(scale==nil) scale=drawable.spr.scale

  sspr((sprite%16)*8,
        flr((sprite/16))*8,
        size_x,
        size_y,
        drawable.pos.x-(size_x*scale/2),
        drawable.pos.y-(size_y*scale/2),
        size_x*scale,
        size_y*scale,
        drawable.spr.flip_x,
        drawable.spr.flip_y)
end

function make_text(content, pos, ttl, type, color)
  local text={pos={x=pos.x,y=pos.y}, ttl=ttl,type=type}

  if(type==TEXT_TYPE_SIGNAL) then
    text.signal=content
    text.played=false
    text.current=1
    text.color=color or 7
  elseif(type==TEXT_TYPE_POPUP) then
    text.content=content
  end

  return text
end

function make_ship(health)
  return {

    spr={frame=flr(rnd(8)), start=64, steps=8, size_x=2, size_y=1, flip_x=false, flip_y=false, scale=1},
    mov={dx=0,dy=0,df=0},

    max_health=health,
    health=health,
    destroyed=false,

    pos={x=64,y=64},

    shots={},
    lasers={},

    inertia_rotation=5,
    current_inertia_rotation=0,
    inertia_rotation_once_it_started=2,
    max_speed=1.5,
    inertia_speed_factor=1,

    last_shot=0,
    current_shots=0,
    max_consecutive_shots=10,
    min_shot_decay=0.01,
    shot_decay=0.01,
    shot_decay_increment=0.01,

    current_energy=100,
    max_energy=100,
    min_energy_gain=0.01,
    energy_gain_increment=0.01,
    energy_gain=0.01,
    energy_consumption=3,
    energy_depleted=0,

    weapon=WEAPON_CANNON,

    kills={current_wave_asteroids=0, current_wave_asteroids_before_spawn=5, asteroids=0, ships=0},

    type=SHIP
  }
end

function get_edge_position()
  local side=flr(rnd(4))
  local pos={x=rnd(0,128),y=rnd(0,128)}

  if(side==0) then pos.x=1
  elseif(side==1) then pos.x=127
  elseif(side==2) then pos.y=1
  elseif(side==3) then pos.y=127
  end

  return pos
end

function make_asteroid()
  local scale=rnd(1.5)+0.5

  return {
    spr={frame=flr(rnd(16)),start=0,steps=16,size_x=2,size_y=2,flip_x=rnd(2)>1,flip_y=rnd(2)>1,scale=scale},
    pos=get_edge_position(),

    mov={dx=rnd(2)-1,
    dy=rnd(2)-1,
    df=flr(rnd(6))-3},
    health=27*scale,
    destroyed=false,
    type=ASTEROID
  }
end

pointer=
{   
    pos= { x=0, y=0 },
    spr= {frame=0, start=123, steps=1, size_x=1, size_y=1, flip_x=1, flip_y=1, scale=1},
    mb_l=0, mb_r=0, omx=0, omy=0, 
    t=180,
    autohide=false,
   
    init=function()
        poke(0x5f2d, 1)
        pointer.t=180
        pointer.pos.x=mid(0,stat(32),127)
        pointer.pos.y=mid(0,stat(33),127)
        pointer.mb_l=0
        pointer.mb_r=0
    end,
   
    update =function()
        pointer.omx=pointer.pos.x
        pointer.omy=pointer.pos.y
        pointer.pos.x=mid(0,stat(32),127)
        pointer.pos.y=mid(0,stat(33),127)
        pointer.mb_l=stat(34)&1
        pointer.mb_r=stat(34)&2
        if (pointer.autohide and pointer.t>0) pointer.t-=1
        if (pointer.t>=0 and (pointer.omx!=pointer.pos.x or pointer.omy!=pointer.pos.y)) pointer.t=180
    end,

    pressed_left=function()
      return (pointer.mb_l==1)
    end,

    pressed_right=function()
      return (pointer.mb_r==2)
    end,

    visible=function()
      return (pointer.t>0)
    end,

    draw=function()
      if (pointer.visible()) draw(pointer)
    end
}

__gfx__
00000011500000000000001210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001224410000000000005246600000000000012d50000000000000052100000000000000000000000000000000000000000000000000000001100000000000
00005244d50000000000124444750000000122444476000000001244446d00000000124442225000000012444100000000152244451000000015224442100000
00012444dd50000000122444d46100000011244444f70000001112444477500000015444446dd000015224444450000001552544445100000015254444510000
001224444dd5000000112444ddd500000151144ddd6700000011544d44f75000005244dd44765000055d2dd446d4d10001522d44444500000055544444450000
0011555444d4000005115444ddd5000002114444ddd400000115444ddd77500001dd64dd4477600005dd5dd47776d50001d5dd5476d41000005555e644451000
0111555477444000021115474dd410000211d674ddd50000011d664dddd6100005dd6dddd677600005d25ddd7776510001555d56777dd100012555677e4d1000
0555555d77f4400001111677f444100002516674dd44000005d6674ddd55000005d66dddd477400001d2dddd676740000122dddd6765d1000125d5d776dd0000
0022555d777d0000005d567774441000005d67774444000005d677e444450000015d644454540000005245d4777610000022454667760000012256d66d5d0000
00024d6677d000000005d67777d50000005d677744440000002d667444d10000001dd44445d500000012244555440000002245554664000000155556664d0000
0001d566641000000000566f751100000005d6dddd50000000055ddd4420000000005544dd550000000124d55475000000015555444200000000555444d10000
00000122000000000000551511000000000010150000000000000115110000000000011522200000000001556dd0000000000152475000000000052466500000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000002100000000000005250000000000005dd5000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000055000000000000001610000000000000016600000000
000001200000000000000002500000000000002025100000000001200000000000050010000000000015d420100000000005d442100000000005d54410000000
0000144441000000000052444510000000015544455000000011254444d50000015d444442200000005d444445000000002d2444dd10000000122244d5100000
000554444450000000112444455000000015444445510000005d44444555000001dd444444dd000001244444444000000522244444410000001524444dd20000
00111444444450000055444444540000005664444455100005d64444455d100001d444445555600015422444444d000001522444446400000011444444440000
00511664445560000116644444541000015644444455400005d64444455d50000044444455557000555244445557000005114445547700000015245544740000
0251567644555000015d6644455540000156444455544000055444444555400005dd44445557700005515445555d60000015545555d700000015555556771000
0212d6664dd56000005dd44dd5557000015144d555564000051dd4555554500005ddd5555555500000115555556760000015555555570000011555555d770000
00115665dd5d0000005dd5ddd555100000515ddd55560000055dddd555640000015555555444000000155555556d50000015555557770000015555555d760000
00011d6dddd500000005d5dd555d000000525d55555d0000002d5555557500000051155574400000001155d444420000005d644445d400000054445d66650000
0001526445d500000002225556650000000255556d60000000551555665000000051555d665000000055d6d4440100000005d444444000000015d54454500000
000002246520000000055dd565500000000555566d50000000055ddd65000000000155dd1100000000015d55510000000001055d510000000000155511000000
0000026d54000000000015d521000000000055540000000000000225500000000000011000000000000000000000000000000001000000000000001000000000
00000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000010000000000000000000000
00000003b30000000000000000031000000000d5000000000000dd0310d000000000050000d000000000060030cd000000000000160000000001300000000000
00000053bb0000000016d51553bbb000000035b3d1000000010001355bd00000001053bb3a6d010000000631dbd000000000001d3adb00000003bbd3551dd500
000005bbb3d00000000035dbbbbd000011c13bbbb66bb30006c05d5bbbd000000006d3bbbbbdd1000000053bb56d0cd00033366bbbbb0cd1000053bbb5d35000
0066d3db35dddd0000033bb56bd5000000003d6bbbbbbb100015bbbbb6bb00000000d53bbbd600000000536bbbbbdd00003bbbbbb66b000000001535dbbbb000
00005bbbbbbd100000c1633bbbd00000cdc0dbbbd6500000000dd6dddbbbb0000000055bbbd0000000035bbdd6d6d0000000056dbbb70ccc00000db3bb371c00
00000d7006d300000c10003dd150000001116b6d00000000000000000003100000000003b30000000001b00000000000000000005d37150000000655bb000110
0000050000d00000000001cd000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000d1500000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009c9000009a900000090c0000090a0000000000000000000000000000000000000a0000000c00000000000000000000000000000000000000c0900000a09000
000a0000008c80000000a0000008c0000000090000008900000a0900000c8900000c0000008a80000090a0000098c0000090000000980000000a0000000c8000
000c0000000a0000000c0900000a890000cacac000acaca00000c0000008a000009a9000009c9000000c0000000a80000acaca000cacac000090c0000098a000
00000000000000000000000000000000000009000000890000090a0000090c00000c0000000a000000a0900000c0900000900000009800000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000000000000000600000000000000000700000040000002000000040700000000000000044020400200008802800008877400088
0000070000000000000000000000000000000000006000000007004047000200000004000000000000000000000a040047720770228808070844404400000008
00000000000000000000000000000000000000000000000004070000000000000000000000700000000000000799440044700444aaa807770000000242000500
0000000000700000000000000070000000000000000000000000207000004000000070200000000200000000004842000089990400a8aaa0004a80047000a570
0000000000000000000000000000007000000000000000000020400020072000000000000000000000000000044297000089a920888aa00a80075a00700a7070
000000000000000000005000000000000000000000000000070000000000040000700000000000000000000004c77800248992200aa008870400700075000070
00000000000000000000000000000000006000000000000000000040000000000000004000000000000000000000700000000044070000874400004405000000
07000000000000000000000000007000000000000000000000004007700000040000000070000000000000000000000040000004770000880004008800040004
000000055500000000000000000000007000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55000005500000500000000008000070000000000000000000000000000000000000000000000000000000c00770077000099000000aa0000009900000088000
00000000000000500000000000700c000000000000000000000000f000000000000c0000000000000000000007000070009aa90000a99a000098890000899800
4000000000000000000c700000000000000000000500000000000000000cc00000077c0000700700070000000000000009a99a900a9889a009899890089aa980
00000000000000000007a000000000000000000000000000000000000000c00000c000000000000000000070000000000a9889a009899890089aa98009a99a90
5000005000000000000000000070070000000000000000000000000000000000000c00000c0070c00000000007000070098008900890098009a00a900a9009a0
55000057000000050000000007000070000000000000000000000000000000000000000000000c00000700000770077008000080090000900a0000a009000090
77000077000000550000000000000000700000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aa5000000a50000009aa000049900009a90000000900000009a90000494000007c770000000777000000007c70000000000000000000000000000000000000
0a9aa00000094000009aaa9009aaaa500aaaa0000029200000aa99004aaaaa50007077000000777c0000000077c7000000000000000000000000000000000000
5a99a9000029400002aa9a909aa9aaa05aa9a9000029200009a94900aa999a90007c7c00000777c7777777077c77700000000000000000000000000000000000
5a999a000029400009aa9a90aaa9aaa95aa9aa00002920000a999900aaaa99a0007c7c0000077c77c077c0cc07c7770000000000000000000000000000000000
09949a00002940000aaa9a90aaa9aaa90aa9aa00002920005aa99a000a9999a000777c0000777700777777770077c77000000000000000000000000000000000
09999a90002940000aaa9a000aa9aaa00aa9aa90002920000a999a00099a9aa000777c000c7c7000c0cc77c00007c77700000000000000000000000000000000
0049aa900029400000aaa9000aaaaa0009aaaa00004920000a99990000999a0000777c00c7777000000000000000777c00000000000000000000000000000000
0009000000090000000a500000a9a00000990000000900000009900000990000007c770077770000000000000000077700000000000000000000000000000000
0000000000000000000000000000000000000000000000000055000000600055000000000000000000000000000000009000000c000000990000000c00000000
0000000000000000000000000000000000000000000000000556080000665508000000000000000006000000555066000000000c000000000000000000000000
0000000000000000000000000000000000000000500000005560880000006508000aa0080000aa006600555c0000066000000007000000000000000000000000
000000000000000000000000000000000000005505500000506058000000605800aa055000000aa06000000c0009906000000007000000000000000000000000
000000000000000000000000000000000000500000500500506558000000068800a00000000050a06000000c0000900000000000000000000000000000000000
000000000000000000000005500000000005006006000000000500000088000000000000000000000008000c0000050000000000000000000000000000000000
0000005555000000000000566500000000000600006050000000009a0998000005000000000000500000000c0000055000000000000000000000000000000000
0000005665000000000005600650000000500608806000000000009cc90800000000000c00008050005500070000050000000000000000000000000000000000
0000005665000000000005600650000000050088800060500000508cc0099006aa0000ccc0000000000ccc777cccc000cc770000000077ccc00000000000000c
00000055550000000000005665000000000066080006650000000508009900060aa0000c00000000000000070000000000000000000000000000000000000000
000000000000000000000005500000000050060000660500006005580008006605000000000000550900000c0000008000000000000000000000000000000000
000000000000000000000000000000000005566000005000506000000088066005000000000000500905000c0000000000000000000000000000000000000000
000000000000000000000000000000000000000050050000556000000880055005580000008800000605500c0050000000000007000000000000000000000000
000000000000000000000000000000000000550000000000056600000000050000080000000000a00660000c0550066000000007000000000000000000000000
00000000000000000000000000000000000000050000000000566000000650050000a000005500a000660000009066000000000c000000000000000000000000
00000000000000000000000000000000000000000000000000000000006600550000aa0000500aa000000000000000005000000c000000060000000c00000000
000000000880088000000cc000000000000070000000700000007000000070000000700000007000000aa00000a00a000a0000a0a000000a0000000000000000
08808800888888880000cc7000000c000000700000007000000070000007c700000070000000700000a00a000a0000a0a000000a000aa0000000000000000000
8887888088877888000cc7000000c0000000700000007000000777000007a70000077700000070000a0000a0a000000a000aa00000a00a000000000000000000
087778008777777800cc7000000c0000000070000007f7000007b7000007a7000007970000077700a000000a000aa00000a00a000a0000a00000000000000000
0087800087777778000cc7000000c0000000700000077700000787000007c700000797000007e700000aa00000a00a000a0000a0a000000a0000000000000000
000800000887788000cc7000000c00000000700000007000000777000007c700000777000000700000a00a000a0000a0a000000a000aa0000000000000000000
00000000008888000cc7000000c000000000700000007000000070000007c70000007000000070000a0000a0a000000a000aa00000a00a000000000000000000
00000000000000000cc0000000000000000070000000700000007000000070000000700000007000a000000a000aa00000a00a000a0000a00000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000667d55555555511000000000000000000000000005050505050
00000000000000000000000000000000000000000000000000000000000000000000000000000556666d54444500000000000000000000000000005050505050
00000000000000000000000000000000000000000000000000000000000000000000000000000005455445dd5100000000000000000000000000005050505050
0000000000000000000000000000000000500000000000000000000000000000000000000000000011155511000000000050000000000000000000b3b3b05050
0000000000000000000000000000000000000000000000000000000000000000000000000000000011155511000000000000000000000000000003b3b3b3bb33
0000000000060000000000000000000000000000000000000000000000000000000000000006000000001000000000000000000000000000000003b3b3b3bb33
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000070000000003b3b3b3bb33
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000f000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000005000003b3b3b3bb33
0000000000800000000000909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000008000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000900000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000008007000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000003b3b3b3bb33
0000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000600000000000003b3b3b3bb33
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000070090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000022700008000000060000000000000000000000000000000000000000000000000000000000000006000000000000000003b3b3b3bb33
0000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000000000000020000000000000060000000000000000000000000000000000000000000000000000000000000006000000000000000003b3b3b3bb33
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0000000000091000000000000050000000000000000000000000000000000000000000000000000000000000005000000000000000000000000003b3b3b3bb33
016d515559888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
00095d88888d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
0099885568d5000000000000000000000000000f000000000000000000000000000000000000000000000000000000000000000f00000000000003b3b3b3bb33
0c16998888d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3b3b3bb33
c10009ddd15000000000000600000000880000000000000000000006000000000000000000000000000000060000000000000000000000000000000000000000
00001cdd000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
00000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
00000000000000000000000000000000999800000080000000000000000000000000000000000000000000000000000000000000000000000000055055555555
00000000000000000000000000000000880000000008000000000000000000000000000000000000000000000000000000000000000000000000055055585555
00000000000000000000000000000000000000008990000000000000000000000000000000000000000000000000000000000000000000000000055055ccac55
00000000000000000006000000000000000000000080000000060000000000000000000000000000000600000000000000000000000000000006055055585555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
00000000000007000000000000000000000000000000000000000000000007000000000000000700000000000000000000000000000000000000055055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
0000000000060000000000000000000000000000000000000000000000060000cc00000000060000000000000000000000000000000000000000055055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
0000000000000000000000000000000000000000000000000000000000000000c0c0000000000000000000000000000000000000000000000000055055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055555555
000000000000000000000000000000000000000000000000000600000000060030cd000000000000000000000000000000000000000000000006055055555555
0000000000000000000000000000000000000000000000000000000000000631dbd0000000000000000000000000000000000000000000000000055055555555
000000000000000000000000000000000000000000000000000000000000053bb56d0cd000000000000000000000000000000000000000000000055055555555
000000000000000000000000000000000000000000000000000000000000536bbbbbdd0000000000000000000000000000000000000000000000055000555555
0000000000000000000000000000000000000000000000000000000000035bbdd6d6d00000000000000000000000000000000000000000000000055550555555
000000000000000000000000000000000000000000000000000000000001b0000000000000000000000000000000000000000000000000000000011550555555
00000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000500000000000000000011550555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011550555555
00000000000600000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000011550555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011550555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011dd0555555
00000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000700000000011dd0555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011dd0555555
0000000f000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000011dd0555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011dd0555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011dd0555555
00000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000050000011dd0555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011dd0555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011dd0555555
00000000000000000000000000000000007700770000000000000000000000000000000000000000000000000000000000000000000000000000011dd0555555
00000000000000000000000000000000007000070000000000000000000000000000000000000000000000000000000000000000000000000000011dd0555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011dd0555555
00000000000000000000070000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000011dd0555555
00000000000000000000000000000000007000070000000000000000000000000000000000000000000000000000000000000006000000000000011dd0555555
00000000000000000000000000000000007700770000000000000000000000000000000000000000000000000000000000000000000000000000011dd0005555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000060000000000000000011ddcc05555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000060000000000000000011ddcc05555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000000000000500000000000000000000000000000000000000000000000000000000000000050000000000000000000000000011ddcc05555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000000000000000246000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000000000000015566d000000f000000000000000000000000000000000000000000000000000000000000000f000000000000011ddcc05555
00000000000000000000000000025d6dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
0000000000000000000000060002567ed00000000000000000000006000000000000000000000000000000060000000000000000000000000000011ddcc05555
00000000000000000000000000055444500000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000000000000012442000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc05555
00000000000000000006000000000000000000000000000000060000000000000000000000000000000600000000000000000000000000000006011ddcc07055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc77055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc77055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc77055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc77055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc77055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc77055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc77055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc77055
00000000000007000000000000000000000000000000000000000000000007000000000000000700000000000000000000000000000000000000011ddcc77055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc77055
00000000000600000000000000000000000000000000000000000000000600000000000000060000000000000000000000000000000000000000011ddcc77055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011ddcc77055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055599555055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055988955055
06606660666066006660666006600000666066606660006660000000000000000000000000000000000000000000000000000000000000000000059899895055
600060606000606006000600600006006000606060600660660000000000000000000000000000000000000000000000000000000000000000000589aa985055
60006600660060600600060066600000666060606060666066660000000000000000000000000000000000000000000000000000000000000006059a55a95055
6000606060006060060006000060060000606060606006606600000000000000000000000000000000000000000000000000000000000000000005a5555a5055
06606060666066606660060066000000666066606660006660000000000000000000000000000000000000000000000000000000000000000000055555555055

__map__
ff00000000ff000065ffffffffffff7500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000ff000000ffffff64ffffff64ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000620000ffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000610000000000ffffff65ff65ffff00000000750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000ffff65ffffffffff76000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff00000000ff00ffffffffffff65ffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000ffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00610000ff00006164ffffffffffffff00000000760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565ffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000ff0000ffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
012600002b7542b7512b7512b7512b7512b755000000000030754307513075130751307513075500000000002c7542c7512c7512c7512c7512c75500000000002975429751297512975129751297550000000000
0126000007252132321f232132321f232132321f2321323207252132321f232132321f232132321f2321323208252142322023214232202321423220232142320825214232202321423220232142322023214232
012600000165022601226010165122601016512260100000016502260122601016512260101651226010000001650226012260101651226010165122601000000165022601226010165122601016512260122601
012500002b5502c5512e55030552305523055230552245520850100501085010050108501005010850100501295502e5512c5502b5522b5522b5522b5522b5520050100501005010050100501005010050100501
010400002825600206222560020620256002061f256002062825600206222560020620256002061f256002062825600206222560020620256002061f256002062825600206222560020620256002061f25600206
010400002915300003000032915329153000032915300003000032915300003291530000329153000032915300003000032915300003000032915300003000030000300003291530000300003000032915300000
001000001a65019650186501865017650176501765016650156501465012650106502f6500f6502a6500e6500d6500c6500c6500d6500e6500f65010650106501165012650136501465016650186501a6501c650
010100003a15138151321512f1512b15127151211511d1511b151191511615114151101510f1510d1510c1510a151081510715105151031511210101151101010f1010f1010f1010e1010e1010e1010f10110101
00010000101500f1501a1500e150191500e15027150181500e150001001815028150001000f1500d150001000c150281501015000100281500010016150101500b15016150281500c1500f150281501515028150
0001000003150031500315003150031501615015150031501415002150141501415013150131501315012150121501c150001001b150001001b1500e1500e1500e15009150091500815006150071500715000100
010200000605105051050510605108051090510b0510d0510f051120510000115051190511e05123051280513f051000010000100001000010000100001000010000100001000010000100001000010000100001
010200002823228232282322823200202002020020200202282002820028200282000020200202002020020228200282002820028200002020020200202002022820028200282002820000202002020020200202
00030000266372663726637256372563725637246372463723637000072263721637000071f6371e637000071c6371a6370000718637000071663716637156370000714637136371263712637000070000700007
010300003b605386023660233602316022e6122c612296122762226622216221f6321c6321b632186421664215652136621267210672106720f6720e6720e6720d6620c6620c6520b6570a646066300962008600
010100001355111551115510c551115511155111551115510c5511155111551115511155111551115510050100501005013355130551305512e5512e551005012e551335512e5513055130551305513055130551
__music__
00 00020143
00 00020143
03 00020103
00 04424344
00 04054344
03 06424344
03 00024344

