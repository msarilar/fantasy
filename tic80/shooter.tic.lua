-- title:  shooter
-- author: max
-- desc:   short description
-- script: lua
function pal(c0, c1)
  if(c0==nil and c1==nil)then for i=0,15 do poke4(0x3FF0*2+i,i)end
  else poke4(0x3FF0*2+c0,c1)end
end

function get_centers(drawable)
  local size_x = 8 * drawable.spr.size_x
  local size_y = 8 * drawable.spr.size_y

  local positions = {}

  for i = 0, drawable.spr.size_x - 1 do
      for j = 0, drawable.spr.size_y - 1 do
          local pos = {}
          local dx = drawable.pos.x - (size_x * drawable.spr.scale / 2) * i
          local dy = drawable.pos.y - (size_y * drawable.spr.scale / 2) * j
          pos.x = 4 + (dx * 2 + i * 8) / 2
          pos.y = 4 + (dy * 2 + j * 8) / 2
          table.insert(positions, pos)
      end
  end

  return positions
end

function sgn(v)
  if v == 0 then
      return 0
  elseif (v > 0) then
      return 1
  else
      return -1
  end
end

function del(t, item)
  for i, o in ipairs(t) do
      if (o == item) then
          table.remove(t, i)
          break
      end
  end
end

function normalize(pos1, pos2)
  if (pos2 == nil) then
      pos2 = {x = 0, y = 0}
  end

  local _x = (pos1.x - pos2.x)
  local _y = (pos1.y - pos2.y)

  local distance = math.sqrt(_x * _x + _y * _y)

  return {_x / distance, _y / distance, x = _x / distance, y = _y / distance}
end

function update(updatable)
  if ((updatable.locked == nil or updatable.locked == false) and frame%2==0) then
      updatable.pos.x = updatable.pos.x + updatable.mov.dx + global_x
      updatable.pos.y = updatable.pos.y + updatable.mov.dy + global_y
  end
  if (updatable.mov.df ~= 0 and clock % updatable.mov.df == 0) then
      local new_frame = (updatable.spr.frame + 1) % updatable.spr.steps
      if (new_frame == 0 and updatable.spr.frame ~= 0) then
          updatable.spr.played = true
      end
      updatable.spr.frame = new_frame
  end

  if (updatable.effect_type == nil and not (updatable.locked)) then
      updatable.centers = get_centers(updatable)
  end
end

function get_edge_position()
  local side = math.random(4)
  local pos = {x = math.random(0, 240), y = math.random(0, 136)}

  if (side == 1) then
      pos.x = 0
  elseif (side == 2) then
      pos.x = 240
  elseif (side == 3) then
      pos.y = 0
  elseif (side == 4) then
      pos.y = 136
  end

  return pos
end

function make_asteroid()
  local scale = math.random(1, 2)

  local ast = {
      spr = {
          frame = math.random(16)-1,
          start = 0,
          steps = 16,
          size_x = 2,
          size_y = 2,
          flip_x = math.random(2) > 1,
          flip_y = math.random(2) > 1,
          scale = scale
      },
      pos = get_edge_position(),
      mov = {
          dx = math.random()*2 - 1,
          dy = math.random()*2 - 1,
          df = math.floor(math.random(6)) - 3
      },
      health = 27 * scale,
      destroyed = false,
      type = ASTEROID
  }
  
  update(ast)

  return ast
end

function make_ship(health)
  local sh = {
      spr = {
          frame = math.random(8)-1,
          start = 64,
          steps = 8,
          size_x = 2,
          size_y = 1,
          flip_x = false,
          flip_y = false,
          scale = 1
      },
      mov = {dx = 0, dy = 0, df = 0},
      max_health = health,
      health = health,
      destroyed = false,
      pos = {x = 120, y = 78},
      shots = {},
      lasers = {},
      inertia_rotation = 5,
      current_inertia_rotation = 0,
      inertia_rotation_once_it_started = 2,
      max_speed = 1.5,
      inertia_speed_factor = 1,
      last_shot = 0,
      current_shots = 0,
      max_consecutive_shots = 10,
      min_shot_decay = 0.01,
      shot_decay = 0.01,
      shot_decay_increment = 0.01,
      current_energy = 100,
      max_energy = 100,
      min_energy_gain = 0.01,
      energy_gain_increment = 0.01,
      energy_gain = 0.01,
      energy_consumption = 3,
      energy_depleted = 0,
      weapon = WEAPON_CANNON,
      kills = {current_wave_asteroids = 0, current_wave_asteroids_before_spawn = 5, asteroids = 0, ships = 0},
      type = SHIP
  }
  
  update(sh)

  return sh;
end

frame = 0
function TIC()
  frame = (frame + 1)%2
	pointer_x, pointer_y, pointer_left, pointer_middle, pointer_right, pointer_scrollx, pointer_scrolly = mouse()
	_update()
  _draw()
end

function init()

  global_x = 0
  global_y = 0
  clock = 0
  music(6)

  directions = {
    normalize({x = 0, y = -1.5}), --up
    normalize({x = 1, y = -1}), --up/right
    normalize({x = 1.5, y = 0}), --right
    normalize({x = 1, y = 1}), --down/right
    normalize({x = 0, y = 1.5}), --down
    normalize({x = -1, y = 1}), --down/right
    normalize({x = -1.5, y = 0}), --right
    normalize({x = -1, y = -1}) --up/right
  }

  asteroid_palette = {
    {1, 1},
    {5, 5},
    {13, 13},
    {2, 2},
    {4, 4},
    {7, 7},
    {6, 6}
  }

  wave = 1
  current_wave = 0
  timer = 0

  STATE_BEFORE_WAVE = 1
  STATE_DURING_WAVE = 2
  STATE_WAVE_COMPLETED = 3
  STATE_WARP = 4
  STATE_GAME_OVER = 5

  TEXT_TYPE_POPUP = 1
  TEXT_TYPE_SIGNAL = 2

  ASTEROID = 1
  SHIP = 2

  UPGRADE_MAX_LIFE = 1
  UPGRADE_MAX_ENERGY = 2
  UPGRADE_MAX_SPEED = 3

  WEAPON_CANNON = 4
  WEAPON_LASER = 5
  WEAPON_PLASMA = 6

  POWERUP_BOOST = 1

  upgrades = {
    0,
    --max life
    0,
    --max energy
    0,
    --max speed
    1,
    --cannon
    0,
    --laser
    0
  --plasma
  }

  current_state = STATE_BEFORE_WAVE

  BUTTON_LEAVE = 1
  hud = {
    energy = {
        start_x = 117 + 112,
        start_y = 120 + 8
    }
  }

  available_upgrades = {
    {
        name = "+LIFE",
        base_price = 500,
        locked = true,
        spr = {start = 176, steps = 2, frame = 0, flip_x = false, flip_y = false, scale = 1.2, size_x = 1, size_y = 1},
        mov = {df = 3},
        type = UPGRADE_MAX_LIFE
    },
    {
        name = "+POWER",
        base_price = 500,
        locked = true,
        spr = {start = 178, steps = 2, frame = 0, flip_x = false, flip_y = false, scale = 1.2, size_x = 1, size_y = 1},
        mov = {df = 3},
        type = UPGRADE_MAX_ENERGY
    },
    {
        name = "+SPEED",
        base_price = 500,
        locked = true,
        spr = {start = 186, steps = 4, frame = 0, flip_x = false, flip_y = false, scale = 1.2, size_x = 1, size_y = 1},
        mov = {df = 2},
        type = UPGRADE_MAX_SPEED
    }
  }

  special_offers = {
    {
        name = "CANNON",
        base_price = 1000,
        locked = true,
        spr = {start = 80, steps = 15, frame = 0, flip_x = false, flip_y = false, scale = 3, size_x = 1, size_y = 1},
        mov = {df = 3},
        type = WEAPON_CANNON
    },
    {
        name = "LASER",
        base_price = 1000,
        locked = true,
        spr = {start = 180, steps = 6, frame = 0, flip_x = false, flip_y = false, scale = 2, size_x = 1, size_y = 1},
        mov = {df = 2},
        type = WEAPON_LASER
    },
    {
        name = "PLASMA",
        base_price = 1000,
        locked = true,
        spr = {start = 136, steps = 4, frame = 0, flip_x = false, flip_y = false, scale = 1.5, size_x = 1, size_y = 1},
        mov = {df = 3},
        type = WEAPON_PLASMA
    }
  }

  offers = {}

  credits = 500

  buttons = {
    {
        text = " buy ",
        hover = false,
        disabled = false,
        rect = {x = 20, y = 62, width = 22, height = 10},
        click = function(self)
            buy(self, 1)
        end
    },
    {
        text = " buy ",
        hover = false,
        disabled = false,
        rect = {x = 50, y = 62, width = 22, height = 10},
        click = function(self)
            buy(self, 2)
        end
    },
    {
        text = " buy ",
        hover = false,
        disabled = false,
        rect = {x = 80, y = 62, width = 22, height = 10},
        click = function(self)
            buy(self, 3)
        end
    },
    {
        text = "repair:500\136",
        hover = false,
        disabled = false,
        rect = {x = 20, y = 80, width = 62, height = 10},
        click = function(self)
            if (not (self.disabled) and credits >= 500) then
                ship.health = ship.max_health
                credits = credits - 500
                self.disabled = true
            end
        end
    },
    {
        text = "leave",
        hover = false,
        disabled = false,
        rect = {x = 80, y = 80, width = 22, height = 10},
        click = function(self)
            current_state = STATE_WARP
            music(-1, 1000)
            texts = {}
            timer = 100
        end
    }
  }

  boost_powerup = {
    in_use = false,
    type = POWERUP_BOOST,
    pswap = {{8, 6}, {15, 14}},
    pos = {x = hud.energy.start_x + 4, y = hud.energy.start_y + 4},
    mov = {df = 1, dx = 0, dy = 0},
    spr = {
        frame = 0,
        start = 124,
        steps = 4,
        size_x = 1,
        size_y = 1,
        flip_x = false,
        flip_y = false,
        played = false,
        scale = 1
    },
    locked = true
  }

  powerup = boost_powerup

end

init()

function update_offers()
  local arr = ({{1, 2}, {2, 1}, {1, 3}, {3, 1}, {3, 2}, {2, 3}})[math.floor(math.random(1, 5))]
  offers = {}
  for i = 1, 3 do
      if (i == 3) then
          local offer = special_offers[math.random(#special_offers)]
          offer.pos = {x = 30 * i, y = 42}

          offer.price = offer.base_price + 200 * upgrades[offer.type]
          table.insert(offers, offer)
      else
          local offer = available_upgrades[arr[i]]

          offer.pos = {x = 30 * i, y = 42}
          offer.price = offer.base_price + 200 * upgrades[offer.type]
          table.insert(offers, offer)
      end
  end

  for i, btn in ipairs(buttons) do
      btn.disabled = false
  end
end

update_offers()

ennemies_to_spawn = 1

asteroids = {}
ship = make_ship(200)
ship.weapon = WEAPON_CANNON

warp_started = false

ennemies = {}
ships = {}
loots = {}
texts = {}
table.insert(ships, ship)

star_layers = {
  {
      sprite_x = 0,
      sprite_y = 0,
      pos = {x = 0, y = 0}
  },
  {
      sprite_x = 8,
      sprite_y = 0,
      pos = {x = 0, y = 0}
  },
  {
      sprite_x = 16,
      sprite_y = 0,
      pos = {x = 0, y = 0}
  }
}

table.insert(asteroids, make_asteroid())
screenshake = 0
effects = {}

health_colors = {
  {2, 2, 2, 2, 2, 15}, --0%,
  {6, 6, 6, 6, 6, 9}, --25%,
  {14, 14, 14, 14, 14, 9}, --50%,
  {5, 5, 5, 5, 11, 11, 11}, --75%,
  {5, 5, 5, 5, 5, 5, 11} --100%,
}

function buy(button, index)
  if (not (button.disabled) and credits >= offers[index].price) then
      button.disabled = true
      credits = credits - offers[index].price
      if (index == 3) then
          ship.weapon = offers[index].type
          upgrades[ship.weapon] = upgrades[ship.weapon] + 1
      else
          upgrades[offers[index].type] = upgrades[offers[index].type] + 1
          ship.max_health = ship.max_health + 10 * (upgrades[UPGRADE_MAX_LIFE])
          ship.health = ship.health + 10 * (upgrades[UPGRADE_MAX_LIFE])
          ship.max_energy = ship.max_energy + 10 * (upgrades[UPGRADE_MAX_ENERGY])
          ship.current_energy = ship.max_energy
          ship.max_speed = ship.max_speed + upgrades[UPGRADE_MAX_SPEED] / 4
      end
  end
end

function make_ennemy(scale)
  local ennemy = make_ship(50)

  ennemy.spr.scale = scale
  ennemy.health = (ennemy.health + 10 * current_wave) * scale
  ennemy.max_speed = ennemy.max_speed / scale
  ennemy.inertia_speed_factor = ennemy.inertia_speed_factor * scale
  ennemy.weapon = 3 + math.floor(math.random(2)) + 1
  ennemy.pswap = {{11, 8}, {3, 9}}
  ennemy.pos = get_edge_position()
  return ennemy
end

function hcenter(text)
  return 78 - #text * 2
end

function _update()
  clock = (clock + 1) % 100
  timer = math.max(0, timer - 1)

  for i, offer in ipairs(available_upgrades) do
      update(offer)
  end

  for i, offer in ipairs(special_offers) do
      update(offer)
  end

  if (ship.health <= 0 and current_state ~= STATE_GAME_OVER) then
      del(ships, ship)
      current_state = STATE_GAME_OVER
      texts = {}
  end

  if (current_state == STATE_GAME_OVER) then
      if (#texts == 0 and timer == 0) then
          table.insert(texts, make_text("game over", {x = 78 - #"game over" * 2, y = 10}, -1, TEXT_TYPE_SIGNAL, 12))
          timer = 50
      elseif (#texts == 1 and timer == 0) then
          table.insert(
              texts,
              make_text(
                  "another will replace you",
                  {x = 78 - #"another will replace you" * 2, y = 20},
                  -1,
                  TEXT_TYPE_SIGNAL
              )
          )
          timer = 100
      elseif (#texts == 2 and timer == 0) then
          table.insert(texts, make_text("score", {x = 10, y = 50}, -1, TEXT_TYPE_SIGNAL))
          timer = 50
      elseif (#texts == 3 and timer == 0) then
          table.insert(
              texts,
              make_text("asteroids:         " .. ship.kills.asteroids, {x = 10, y = 65}, -1, TEXT_TYPE_SIGNAL, 4)
          )
          timer = 30
      elseif (#texts == 4 and timer == 0) then
          table.insert(
              texts,
              make_text("pirates  :         " .. ship.kills.ships, {x = 10, y = 75}, -1, TEXT_TYPE_SIGNAL, 8)
          )
          timer = 30
      elseif (#texts == 5 and timer == 0) then
          table.insert(texts, make_text("credits  :         " .. credits, {x = 10, y = 85}, -1, TEXT_TYPE_SIGNAL, 10))
          timer = 30
      elseif (#texts == 6 and timer == 0) then
          table.insert(
              texts,
              make_text(
                  "total    :         " .. (credits * 2 + 100 * ship.kills.asteroids + 1000 * ship.kills.ships),
                  {x = 10, y = 95},
                  -1,
                  TEXT_TYPE_SIGNAL
              )
          )
          timer = 30
      elseif (#texts == 7 and timer == 0) then
          table.insert(
              texts,
              make_text(
                  "press x to be replaced",
                  {x = 78 - #"press x to be replaced" * 2, y = 110},
                  -1,
                  TEXT_TYPE_SIGNAL
              )
          )
      elseif (btn(5) and #texts == 8) then
          init()
      end
  elseif (current_state == STATE_BEFORE_WAVE) then
      if (#texts == 0) then
          table.insert(texts, make_text(">try shooting some asteroids,", {x = 0, y = 0}, -1, TEXT_TYPE_SIGNAL))
          table.insert(texts, make_text("hunter...", {x = 0, y = 6}, -1, TEXT_TYPE_SIGNAL))

          if (wave == 1) then
              table.insert(texts, make_text("aim with mouse", {x = 50 + 80, y = 83}, -1, TEXT_TYPE_SIGNAL, 8))
              table.insert(texts, make_text("left click shoot", {x = 50 + 80, y = 93}, -1, TEXT_TYPE_SIGNAL, 9))
              table.insert(texts, make_text("right click boost", {x = 50 + 80, y = 103}, -1, TEXT_TYPE_SIGNAL, 10))
              table.insert(texts, make_text("arrows to thrust", {x = 50 + 80, y = 113}, -1, TEXT_TYPE_SIGNAL, 11))
          end
      end

      if (ship.kills.current_wave_asteroids >= ship.kills.current_wave_asteroids_before_spawn and #ennemies == 0) then
          current_wave = wave
          current_state = STATE_DURING_WAVE
          music(0)
          timer = math.random(200) + 100
          texts = {}
      end
  elseif (current_state == STATE_DURING_WAVE) then
      if (#texts == 0 and #ennemies == 0 and timer ~= 0) then
          table.insert(texts, make_text(">looks like there are pirates", {x = 0, y = 0}, -1, TEXT_TYPE_SIGNAL, 8))
          table.insert(texts, make_text("around!", {x = 0, y = 6}, -1, TEXT_TYPE_SIGNAL, 8))
      end

      if (#ennemies == 0 and timer == 0) then
          texts = {}
          if (wave == current_wave) then
              for i = 1, wave do
                  local ennemy = make_ennemy(1)
                  table.insert(ships, ennemy)
                  table.insert(ennemies, ennemy)
              end
              wave = wave + 1
          elseif (#loots == 0) then
              current_state = STATE_WAVE_COMPLETED
              ship.mov.dx = 0
              ship.mov.dy = 0
              music(6)
              ship.kills.current_wave_asteroids = 0
              ship.kills.current_wave_asteroids_before_spawn = math.floor(math.random(10)) + 5
              update_offers()
          end
      end
  elseif (current_state == STATE_WAVE_COMPLETED) then
      ship.shots = {}
      ship.mov.dx = 0
      ship.mov.dy = 0

      if (#texts == 0) then
          table.insert(texts, make_text(">thank you for securing the", {x = 0, y = 0}, -1, TEXT_TYPE_SIGNAL, 12))
          table.insert(texts, make_text("system. do you want to buy?", {x = 0, y = 6}, -1, TEXT_TYPE_SIGNAL, 12))
      end

      for i, button in ipairs(buttons) do
          button.hover = not (button.disabled) and is_mouse_over(button.rect)
          if (button.hover and pointer_left) then
              button.click(button)
          end
      end
  elseif (current_state == STATE_WARP) then
      if (warp_started == false) then
          table.insert(texts, make_text(">time to leave this place...", {x = 0, y = 0}, 100, TEXT_TYPE_SIGNAL, 10))

          if (timer == 0) then
              warp_started = true
              ship.mov.dx = directions[ship.spr.frame + 1].x * 75
              ship.mov.dy = directions[ship.spr.frame + 1].y * 75
              screenshake = 200

              for i, swap in ipairs(asteroid_palette) do
                  swap[2] = swap[2] + wave % 16
                  if (swap[2] == 0) then
                      swap[2] = 1 + math.floor(math.random(15))
                  end
              end
              timer = 100
          elseif (timer == 70) then
              music(3, 300)
          else
              table.insert(
                  effects,
                  make_effect(
                      {x = math.random(240), y = math.random(136)},
                      114,
                      3,
                      1,
                      math.random((100 - timer)) / 10,
                      pswap
                  )
              )
          end
      elseif (timer == 0) then
          current_state = STATE_BEFORE_WAVE
          warp_started = false
          music(-1)
          music(6, 1000)
      else
          pswap = {{12, clock % 16}, {7, clock % 16}}
          table.insert(effects, make_effect({x = 120, y = 78}, 119, 4, 1, 5, pswap))

          table.insert(
              effects,
              make_effect({x = math.random(128), y = math.random(128)}, 119, 4, 1, math.random(5), pswap)
          )
          table.insert(
              effects,
              make_effect({x = math.random(128), y = math.random(128)}, 119, 4, 1, math.random(5), pswap)
          )
          table.insert(
              effects,
              make_effect({x = math.random(128), y = math.random(128)}, 119, 4, 1, math.random(5), pswap)
          )
          table.insert(
              effects,
              make_effect({x = math.random(128), y = math.random(128)}, 119, 4, 1, math.random(5), pswap)
          )

          local particle_1 =
              make_effect({x = math.random(128), y = math.random(128)}, 114, 3, 1, math.random(5), pswap)
          particle_1.locked = true
          table.insert(effects, particle_1)

          if (ship.mov.dx > 0) then
              ship.mov.dx = math.max(0, ship.mov.dx - 0.75)
          end
          if (ship.mov.dx < 0) then
              ship.mov.dx = math.min(0, ship.mov.dx + 0.75)
          end
          if (ship.mov.dy > 0) then
              ship.mov.dy = math.max(0, ship.mov.dy - 0.75)
          end
          if (ship.mov.dy < 0) then
              ship.mov.dy = math.min(0, ship.mov.dy + 0.75)
          end
      end
  end

  for i, effect in ipairs(effects) do
      update(effect)
      if (effect.spr.played) then
          del(effects, effect)
      end
  end

  for i, text in ipairs(texts) do
      if (text.type == TEXT_TYPE_POPUP) then
          text.pos.y = text.pos.y - 1
      elseif (text.type == TEXT_TYPE_SIGNAL) then
          if (not (text.played)) then
              text.content = string.sub(text.signal, 0, text.current)
              text.current = text.current + 1
              if (#text.content == #text.signal) then
                  text.played = true
              end
          end
      end

      if (text.ttl ~= -1) then
          text.ttl = text.ttl - 1
          if (text.ttl == 0) then
              del(texts, text)
          end
      end
  end

  if (current_state ~= STATE_WARP) then
      if (#asteroids < 10 and math.random(100) > 90) then
          table.insert(asteroids, make_asteroid())
      end
  end

  for i, ast in ipairs(asteroids) do
      update(ast)
      if (ast.pos.x > 256 or ast.pos.y > 256 or ast.pos.x < -128 or ast.pos.y < -128) then
          del(asteroids, ast)
      end
  end

  update(powerup)

  if (current_state == STATE_BEFORE_WAVE or current_state == STATE_DURING_WAVE or current_state == STATE_GAME_OVER) then
      ship.spr.frame = get_direction_towards({pos = {x = pointer_x, y = pointer_y}}, ship)
      ship.centers = get_centers(ship)

      if (ship.health > 0) then
          local moved = false
          if (btn(0)) then
              moved = true
              ship.mov.dx = ship.mov.dx + (0.1 * directions[ship.spr.frame + 1][1] * ship.inertia_speed_factor)
              ship.mov.dy = ship.mov.dy + (0.1 * directions[ship.spr.frame + 1][2] * ship.inertia_speed_factor)
          end
          if (btn(2)) then
              moved = true
              ship.mov.dx =
                  ship.mov.dx + (0.1 * directions[(ship.spr.frame - 2) % 8 + 1][1] * ship.inertia_speed_factor)
              ship.mov.dy =
                  ship.mov.dy + (0.1 * directions[(ship.spr.frame - 2) % 8 + 1][2] * ship.inertia_speed_factor)
          end
          if (btn(3)) then
              moved = true
              ship.mov.dx =
                  ship.mov.dx + (0.1 * directions[(ship.spr.frame + 2) % 8 + 1][1] * ship.inertia_speed_factor)
              ship.mov.dy =
                  ship.mov.dy + (0.1 * directions[(ship.spr.frame + 2) % 8 + 1][2] * ship.inertia_speed_factor)
          end
          if (btn(1)) then
              moved = true
              ship.mov.dx =
                  ship.mov.dx + (0.1 * directions[(ship.spr.frame + 4) % 8 + 1][1] * ship.inertia_speed_factor)
              ship.mov.dy =
                  ship.mov.dy + (0.1 * directions[(ship.spr.frame + 4) % 8 + 1][2] * ship.inertia_speed_factor)
          end

          if (moved) then
              local pswap = nil
              if (powerup ~= nil and powerup.in_use) then
                  pswap = powerup.pswap
              end
              table.insert(
                  effects,
                  make_effect(
                      {x = ship.pos.x - ship.mov.dx * 2, y = ship.pos.y - ship.mov.dy * 2},
                      119,
                      4,
                      1,
                      math.random(1) + 0.5,
                      pswap
                  )
              )
          end

          if (pointer_left and ship.last_shot < 0 and ship.current_shots < ship.max_consecutive_shots) then
              shoot(ship)
              ship.shot_decay = ship.min_shot_decay
          else
              ship.shot_decay = ship.shot_decay + ship.shot_decay_increment
              ship.current_shots = math.max(0, ship.current_shots - ship.shot_decay)
              ship.last_shot = ship.last_shot - 1
          end

          if (powerup ~= nil and pointer_right and ship.current_energy > 0 and not (ship.energy_depleted)) then
              ship.energy_gain = ship.min_energy_gain
              ship.current_energy = math.max(0, ship.current_energy - ship.energy_consumption)
              start_powerup()
          else
              ship.energy_depleted = ship.current_energy <= 0 or (ship.energy_depleted and ship.current_energy < 50)
              --if(ship.energy_depleted and clock%3==0) then sfx(11,1) end
              ship.energy_gain = ship.energy_gain + ship.energy_gain_increment
              ship.current_energy = math.min(ship.max_energy, ship.current_energy + ship.energy_gain)
              stop_powerup()
          end
      end

      for i, sh in ipairs(ships) do
          if (sh.mov.dx > 0) then
              sh.mov.dx = math.max(0, sh.mov.dx - (1 / sh.inertia_speed_factor / 100))
          end
          if (sh.mov.dx < 0) then
              sh.mov.dx = math.min(0, sh.mov.dx + (1 / sh.inertia_speed_factor / 100))
          end
          if (sh.mov.dy > 0) then
              sh.mov.dy = math.max(0, sh.mov.dy - (1 / sh.inertia_speed_factor / 100))
          end
          if (sh.mov.dy < 0) then
              sh.mov.dy = math.min(0, sh.mov.dy + (1 / sh.inertia_speed_factor / 100))
          end

          if (sh.mov.dx > sh.max_speed) then
              sh.mov.dx = sh.max_speed
          end
          if (sh.mov.dy > sh.max_speed) then
              sh.mov.dy = sh.max_speed
          end
          if (sh.mov.dx < -1 * sh.max_speed) then
              sh.mov.dx = -1 * sh.max_speed
          end
          if (sh.mov.dy < -1 * sh.max_speed) then
              sh.mov.dy = -1 * sh.max_speed
          end

          for i, laser in ipairs(sh.lasers) do
              if (laser.ttl == 0) then
                  del(sh.lasers, laser)
              else
                  laser.ttl = laser.ttl - 1
                  if (laser.target.hit ~= nil) then
                      local hit = laser.target.hit
                      hit.health = hit.health - (laser.damage + laser.damage_mult)

                      table.insert(texts, make_text(laser.damage + laser.damage_mult, hit.pos, 20, TEXT_TYPE_POPUP))

                      if (hit.destroyed == false and hit.health <= 0) then
                          hit.destroyed = true

                          if (hit.type == ASTEROID) then
                              if (sh == ship) then
                                  screenshake = 106
                              end

                              if (math.random(100) > 50) then
                                  table.insert(loots, make_loot(hit.pos))
                              end

                              sh.kills.asteroids = sh.kills.asteroids + 1
                              sh.kills.current_wave_asteroids = sh.kills.current_wave_asteroids + 1
                              table.insert(effects, make_effect(hit.pos, 107, 7, 1, hit.spr.scale))
                              del(asteroids, hit)
                          elseif (hit.type == SHIP and hit ~= sh and (hit == ship or sh == ship)) then
                              table.insert(effects, make_effect(hit.pos, 144, 7, 2, 2.5))
                              for i = 0, math.random(5) do
                                  table.insert(
                                      loots,
                                      make_loot(
                                          {x = hit.pos.x + math.random(10) - 5, y = hit.pos.y + math.random(10) - 5},
                                          1
                                      )
                                  )
                              end
                              del(ennemies, hit)
                              del(ships, hit)
                              if (hit ~= ship) then
                                  if (#texts == 0) then
                                      table.insert(
                                          texts,
                                          make_text(">nice shot!", {x = 0, y = 0}, 50, TEXT_TYPE_SIGNAL)
                                      )
                                  end
                                  sh.kills.ships = sh.kills.ships + 1
                              end
                          end
                      else
                          if (#effects < 20) then
                              table.insert(effects, make_effect(laser.target, 102, 4, 1, laser.target.hit.spr.scale))
                          end

                          laser.target.hit.mov.dx = laser.target.hit.mov.dx + (laser.target.x - laser.start.x) / 10000
                          laser.target.hit.mov.dy = laser.target.hit.mov.dy + (laser.target.y - laser.start.y) / 10000
                      end
                  end
              end
          end

          for i, shot in ipairs(sh.shots) do
              update(shot)
              if (shot.pos.x > 256 or shot.pos.y > 256 or shot.pos.x < -128 or shot.pos.y < -128) then
                  del(sh.shots, shot)
              else
                  for i, other in ipairs(ships) do
                      if (sh ~= other and (sh == ship or other == ship)) then
                          if (is_collision(shot, other)) then
                              table.insert(effects, make_effect(other.pos, 107, 7, 1, 1))
                              screenshake = 106
                              other.health = math.max(0, other.health - shot.damage)
                              table.insert(texts, make_text(shot.damage, other.pos, 20, TEXT_TYPE_POPUP))
                              if (other.health == 0) then
                                  table.insert(effects, make_effect(other.pos, 144, 7, 2, 2.5))
                                  for i = 0, math.random(5) do
                                      table.insert(
                                          loots,
                                          make_loot(
                                              {
                                                  x = other.pos.x + math.random(10) - 5,
                                                  y = other.pos.y + math.random(10) - 5
                                              },
                                              1
                                          )
                                      )
                                  end
                                  del(ships, other)
                                  if (other ~= ship) then
                                      del(ennemies, other)
                                      table.insert(
                                          texts,
                                          make_text(">nice shot!", {x = 0, y = 0}, 50, TEXT_TYPE_SIGNAL)
                                      )
                                      sh.kills.ships = sh.kills.ships + 1
                                  end
                              else
                                  --sfx(12,1)
                                  other.mov.dx = (other.mov.dx + shot.mov.dx / 4)
                                  other.mov.dy = (other.mov.dy + shot.mov.dy / 4)
                              end
                              del(sh.shots, shot)
                              break
                          end
                      end
                  end
              end
          end

          for i, ast in ipairs(asteroids) do
              if (is_collision(ast, sh)) then
                  sh.health = sh.health - 0.1
                  table.insert(effects, make_effect(sh.pos, 102, 4, 1, 1))
                  if (sh == ship) then
                      screenshake = 106
                  --sfx(12)
                  end
              end
              for i, shot in ipairs(sh.shots) do
                  if (is_collision(shot, ast)) then
                      ast.health = ast.health - shot.damage
                      table.insert(texts, make_text(shot.damage, ast.pos, 20, TEXT_TYPE_POPUP))
                      if (ast.health <= 0) then
                          if (sh == ship) then
                              screenshake = 106
                          --sfx(12)
                          end

                          if (math.random(100) > 50) then
                              table.insert(loots, make_loot(ast.pos, 1))
                          end

                          sh.kills.asteroids = sh.kills.asteroids + 1
                          sh.kills.current_wave_asteroids = sh.kills.current_wave_asteroids + 1
                          table.insert(effects, make_effect(ast.pos, 107, 7, 1, ast.spr.scale))
                          del(asteroids, ast)
                      else
                          table.insert(effects, make_effect(shot.pos, 102, 4, 1, 1))
                          ast.mov.dx = (ast.mov.dx + shot.mov.dx / 4) / 2
                          ast.mov.dy = (ast.mov.dy + shot.mov.dy / 4) / 2
                          ast.mov.df = ast.mov.df + 1
                          ast.spr.flip_x = math.random(2) > 1
                          ast.spr.flip_y = math.random(2) > 1
                      end
                      del(sh.shots, shot)
                  end
              end
          end

          sh.health = math.max(0, sh.health)
      end
  end

  for key, loot in ipairs(loots) do
      loot.ttl = loot.ttl - 1
      if (loot.ttl < 0) then
          table.insert(effects, make_effect(loot.pos, 107, 7, 1, math.random(1) + 0.5))
          del(loots, loot)
      else
          if (loot.ttl < 100 and clock % 5 == 0) then
              table.insert(effects, make_effect(loot.pos, 114, 3, 1, math.random(1) + 0.5))
          end
          update(loot)
          if (is_collision(loot, ship)) then
              table.insert(effects, make_effect(loot.pos, 114, 3, 1, 2))

              --sfx(14,1)
              credits = credits + loot.value
              table.insert(texts, make_text(loot.value .. "\136", loot.pos, 20, TEXT_TYPE_POPUP))
              del(loots, loot)
          end
      end
  end

  global_x = -1 * ship.mov.dx
  global_y = -1 * ship.mov.dy

	if(frame%2==0) then
		for i = 1, #star_layers do
				star_layers[i].pos.x = star_layers[i].pos.x + global_x * 2 / i
				star_layers[i].pos.y = star_layers[i].pos.y + global_y * 2 / i
		end
	end

  for key, ennemy in ipairs(ennemies) do
      update_other_ship(ennemy)
  end
end

function start_powerup()
  local direction = directions[ship.spr.frame + 1]

  table.insert(
      effects,
      make_effect(
          {x = ship.pos.x - ship.mov.dx * 2, y = ship.pos.y - ship.mov.dy * 2},
          119,
          4,
          1,
          math.random(1) + 0.5,
          powerup.pswap
      )
  )
  ship.mov.dx = (direction[1]) * 200
  ship.mov.dy = (direction[2]) * 200

  if (powerup.in_use == false) then
      powerup.last_max_speed = ship.max_speed
  end
  ship.max_speed = 5 + upgrades[UPGRADE_MAX_SPEED] / 4
  powerup.in_use = true
end

function stop_powerup()
  if (powerup.in_use) then
      powerup.in_use = false
      if (powerup.type == POWERUP_BOOST and powerup.last_max_speed ~= nil) then
          ship.max_speed = powerup.last_max_speed
      end
  end
end

function shoot(some_ship)
  local direction = directions[some_ship.spr.frame + 1]
  local damage_mult = 0
  if (some_ship == ship) then
      damage_mult = upgrades[some_ship.weapon]
  end
  if (some_ship.weapon == WEAPON_CANNON) then
      if (some_ship == ship) then
          direction = normalize({x = pointer_x, y = pointer_y}, ship.pos)
      end 

      --sfx(7,1)

      local shot = make_shot(some_ship.pos, some_ship.spr.frame, direction)
      shot.mov.dx = shot.mov.dx * 1.2
      shot.mov.dy = shot.mov.dy * 1.2
      shot.delay_between_shots = 0
      shot.damage = 6 + damage_mult
      shot.spr.scale = 2

      table.insert(effects, make_effect(shot.pos, 114, 3, 1, math.random(1) + 0.5))
      table.insert(some_ship.shots, shot)
      some_ship.last_shot = shot.delay_between_shots
      ship.current_shots = ship.current_shots + 0.5
  elseif (some_ship.weapon == WEAPON_PLASMA) then
      --sfx(9,1)
      for i = 0, 3 do
          for j = -1, 1 do
              local index = (some_ship.spr.frame + j) % 8
              direction = directions[index + 1]

              local beam = make_shot(some_ship.pos, some_ship.spr.frame, direction)
              beam.pos.x = beam.pos.x + direction[1] * i
              beam.pos.y = beam.pos.y + direction[2] * i

              beam.mov.dx = beam.mov.dx + ship.mov.dx
              beam.mov.dy = beam.mov.dy + ship.mov.dy
              beam.mov.dx = beam.mov.dx * 1.5
              beam.mov.dy = beam.mov.dy * 1.5
              beam.spr.start = 136 + index % 4
              beam.spr.steps = 1
              beam.delay_between_shots = 0

              beam.damage = 1 + damage_mult
              beam.spr.scale = some_ship.spr.scale
              table.insert(some_ship.shots, beam)
              some_ship.last_shot = beam.delay_between_shots
          end
      end
      ship.current_shots = ship.current_shots + 0.5
  elseif (some_ship.weapon == WEAPON_LASER) then
      --sfx(8,1)

      direction.x = 120 + math.random(30) - 15
      direction.y = 78 + math.random(30) - 15
      if (some_ship == ship) then
          direction = {x = pointer_x, y = pointer_y}
      end
      table.insert(ship.lasers, make_laser(some_ship, direction, damage_mult))
      ship.current_shots = ship.current_shots + 0.3
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

  local a = {x = target.pos.x - 16, y = target.pos.y - 16}
  local b = {x = target.pos.x + 16, y = target.pos.y - 16}
  local c = {x = target.pos.x - 16, y = target.pos.y + 16}
  local d = {x = target.pos.x + 16, y = target.pos.y + 16}

  if (item.pos.x < a.x) then
      if (item.pos.y < a.y) then
          return 7
      end
      if (item.pos.y < c.y) then
          return 6
      end
      return 5
  end

  if (item.pos.x > b.x) then
      if (item.pos.y < b.y) then
          return 1
      end
      if (item.pos.y < d.y) then
          return 2
      end
      return 3
  end

  if (item.pos.y > a.y) then
      return 4
  end

  return 0
end

function update_other_ship(other)
  if (clock % 50 == 0) then
      other.spr.frame = get_direction_towards(ship, other)
  end

  local direction = directions[other.spr.frame + 1]

  local target = ship.pos
  if (ship.health < 0) then
      target = {x = math.random(256) - 128, y = math.random(256) - 128}
  end

  if (math.abs(other.mov.dx) < 0.05 + math.random(1)) then
      other.mov.dx = other.mov.dx + (math.random(1) * (target.x - other.pos.x + math.random(30) - 15) * 0.1)
  end
  if (math.abs(other.mov.dy) < 0.05 + math.random(1)) then
      other.mov.dy = other.mov.dy + (math.random(1) * (target.y - other.pos.y + math.random(30) - 15) * 0.1)
  end

  if (math.random(100) > 95 and ship.health > 0) then
      shoot(other)
  end

  update(other)
end

function camshake()
  if screenshake>105 then
    poke(0x3FF9+1,math.random(-4,4))
    screenshake=screenshake-1
	else
		memset(0x3FF9,0,2)
		if screenshake > 0 then
			screenshake = screenshake - 1
		end
	end
end

function scanline(row)
  if screenshake>105 then
    poke(0x3FF9,math.random(-1,1))    
  end
end

function intersect(x, y, width, height, x3, y3, x4, y4)
  uA = ((x4 - x3) * (y - y3) - (y4 - y3) * (x - x3)) / ((y4 - y3) * (width - x) - (x4 - x3) * (height - y))
  uB = ((width - x) * (y - y3) - (height - y) * (x - x3)) / ((y4 - y3) * (width - x) - (x4 - x3) * (height - y))
  if (uA >= 0 and uA <= 1 and uB >= 0 and uB <= 1) then
      intersectionX = x + (uA * (width - x))
      intersectionY = y + (uA * (height - y))
      return {x = intersectionX, y = intersectionY}
  end
  return nil
end

function intersections(start, target, drawable)
  local x = drawable.pos.x
  local y = drawable.pos.y
  local width = 2 * drawable.spr.scale * drawable.spr.size_x
  local height = 2 * drawable.spr.scale * drawable.spr.size_y
  local results = {}

  local a = intersect(start.x, start.y, target.x, target.y, x - width, y - height, x - width, y + height)
  local b = intersect(start.x, start.y, target.x, target.y, x + width, y - height, x + width, y + height)
  local c = intersect(start.x, start.y, target.x, target.y, x - width, y - height, x + width, y - height)
  local d = intersect(start.x, start.y, target.x, target.y, x - width, y + height, x + width, y + height)

  if (a ~= nil) then
      table.insert(results, a)
  end
  if (b ~= nil) then
      table.insert(results, b)
  end
  if (c ~= nil) then
      table.insert(results, c)
  end
  if (d ~= nil) then
      table.insert(results, d)
  end

  for key, result in ipairs(results) do
      result.hit = drawable
  end

  return results
end

function is_mouse_over(rect)
  return pointer_x > rect.x and pointer_x < rect.x+rect.width and
         pointer_y > rect.y and pointer_y < rect.y+rect.height
end

function is_collision(first, second)
  if (math.abs(first.pos.x - second.pos.x) > 16 or math.abs(first.pos.y - second.pos.y) > 16) then
      return false
  end

  local first_centers = first.centers
  local second_centers = second.centers

  for key, first_center in ipairs(first_centers) do
      for key, second_center in ipairs(second_centers) do
          local distance_x = (second_center.x - first_center.x)
          local distance_y = (second_center.y - first_center.y)

          local distance = math.sqrt(distance_x * distance_x + distance_y * distance_y)

          if (distance < (4 * first.spr.scale + 4 * second.spr.scale) and distance ~= 0) then
              return true
          end
      end
  end

  return false
end

function make_effect(pos, start, steps, size, scale, pswap)
  return {
      spr = {
          frame = 0,
          start = start,
          steps = steps,
          size_x = size,
          size_y = size,
          flip_x = math.random(2) > 1,
          flip_y = math.random(2) > 1,
          played = false,
          scale = scale
      },
      pos = {x = pos.x + math.random(10) - 5, y = pos.y + math.random(10) - 5},
      mov = {dx = 0, dy = 0, df = 4},
      effect_type = 1,
      pswap = pswap
  }
end

function make_loot(origin)
  return {
      spr = {
          start = 128,
          steps = 8,
          frame = 0,
          size_x = 1,
          size_y = 1,
          flip_x = false,
          flip_y = false,
          played = false,
          scale = 1
      },
      pos = {x = origin.x, y = origin.y},
      mov = {dx = 0, dy = 0, df = 3},
      ttl = 200,
      value = math.floor(math.random(100)) + 100
  }
end

function make_laser(source, target, damage_mult)
  local laser = {start = source.pos, damage_mult = damage_mult}

  local dx = (target.x - source.pos.x) * 10
  local dy = (target.y - source.pos.y) * 10

  local target = {x = target.x + dx, y = target.y + dy}

  local hits = {}
  for key, ast in ipairs(asteroids) do
      if (ast.pos.x < 250 and ast.pos.x > -10 and ast.pos.y < 146 and ast.pos.y > -10) then
          for key, intersection in ipairs(intersections(laser.start, target, ast)) do
              table.insert(hits, intersection)
          end
      end
  end

  for key, sh in ipairs(ships) do
      if (sh ~= source and sh.pos.x < 250 and sh.pos.x > -10 and sh.pos.y < 146 and sh.pos.y > -10) then
          for key, intersection in ipairs(intersections(laser.start, target, sh)) do
              table.insert(hits, intersection)
          end
      end
  end

  local closest = target
  closest.distance = 1000
  for key, hit in ipairs(hits) do
      local distance_x = (hit.x - source.pos.x)
      local distance_y = (hit.y - source.pos.y)

      local distance = math.sqrt(distance_x * distance_x + distance_y * distance_y)
      if (distance < closest.distance) then
          closest = hit
          closest.distance = distance
      end
  end

  laser.target = closest
  laser.ttl = math.floor((math.random(2) + 2))
  laser.damage = 1
  return laser
end

function make_shot(source_pos, frame, direction)
  local shot = {
      spr = {
          frame = 0,
          start = 80 + 2 * frame,
          steps = 2,
          size_x = 1,
          size_y = 1,
          flip_x = false,
          flip_y = false,
          played = false,
          scale = 1
      },
      pos = {
          x = source_pos.x + (direction[1] + (sgn(direction[1]) * 8)) / 8,
          y = source_pos.y + (direction[2] + (sgn(direction[2]) * 4)) / 4
      },
      mov = {
          dx = direction[1] * 4,
          dy = direction[2] * 4,
          df = 3
      },
      damage = 8,
      delay_between_shots = 3
  }
  
  update(shot)

  return shot
end

function _draw()
  cls()

  camshake()
  for i = 1, #star_layers do
    draw_stars(i)
  end

  for key, pswap in ipairs(asteroid_palette) do
      pal(pswap[1], pswap[2])
  end
  for key, ast in ipairs(asteroids) do
      draw(ast)
  end
  pal()

  for key, s in ipairs(ships) do
      for key, shot in ipairs(s.shots) do
          draw(shot)
      end
      for key, laser in ipairs(s.lasers) do
          line(
              laser.start.x - 1,
              laser.start.y - 1,
              laser.target.x - 1,
              laser.target.y - 1,
              clock % 16
          )
          line(
              laser.start.x - 1,
              laser.start.y + 1,
              laser.target.x - 1,
              laser.target.y + 1,
              clock % 16
          )
          line(
              laser.start.x + 1,
              laser.start.y - 1,
              laser.target.x + 1,
              laser.target.y - 1,
              clock % 16
          )
          line(laser.start.x, laser.start.y, laser.target.x, laser.target.y, clock % 16)
          line(
              laser.start.x + 1,
              laser.start.y + 1,
              laser.target.x + 1,
              laser.target.y + 1,
              clock % 16
          )
      end
      if (s.pswap ~= nil) then
          for key, pswap in ipairs(s.pswap) do
              pal(pswap[1], pswap[2])
          end
      end
      draw(s)
      print(s.health, s.pos.x, s.pos.y)
      pal()
  end

  for key, loot in ipairs(loots) do
      draw(loot)
  end

  for key, effect in ipairs(effects) do
      if (effect.pswap ~= nil) then
          for key, pswap in ipairs(effect.pswap) do
              pal(pswap[1], pswap[2])
          end
      end

      draw(effect)
      pal()
  end

  for key, text in ipairs(texts) do
      local color = text.color
      if (text.type == TEXT_TYPE_POPUP) then
          color = (clock + math.floor(math.random(15))) % 15
      end
      print(text.content, text.pos.x, text.pos.y, color, true, 1)
  end

  pal()
  draw_hud()
end

function draw_hud()
  if (current_state ~= STATE_GAME_OVER) then
      if (current_state == STATE_WAVE_COMPLETED) then
          draw_hud_shop()
      end

      rect(118 + 112, 0, 9, 127 + 8, 0)
      draw_hud_health()
      draw_hud_energy()
      draw_hud_shots()

      for i = 1, 3 do
          for j = 1, upgrades[i] do
              draw({spr = available_upgrades[i].spr, pos = {x = j * 9 - 5, y = 87 + i * 10}}, 0.9)
          end
      end

      print("credits:" .. credits .. "\136", 0, 131, 6, true, 1, true)
  end
end

function draw_hud_shop()
  for key, button in ipairs(buttons) do
      if (not (button.disabled)) then
          local bg = 0
          local fg = 7
          if (button.hover) then
              bg = 9
              fg = 5
          end
          rectb(button.rect.x, button.rect.y, button.rect.width, button.rect.height, fg)
          rect(button.rect.x + 1, button.rect.y + 1, button.rect.width + 1, button.rect.height + 1, bg)
          print(button.text, button.rect.x + 2, button.rect.y + 3, fg)
      end
  end

  for key, offer in ipairs(offers) do
      print(offer.name, offer.pos.x - 4 - #offer.name, offer.pos.y - 16, 1 + clock % 15)
      draw(offer)
      print(offer.price .. "\136", offer.pos.x - 8, offer.pos.y + 12, 10)
  end
end

function draw_hud_health()
  local health_ratio = ship.health / ship.max_health
  local c = health_colors[math.floor(health_ratio * (#health_colors - 1)) + 1]

  for i = 117 + 112, 127 + 112 do
      if (i % 2 == 0) then
          line(i, 0, i, 35, 7)
      end
  end
  for i = 117 + 112, 127 + 112 do
      local dy = i / (127 - 117)
      line(
          i,
          35,
          i,
          35 - ship.health * 34 / ship.max_health -
              math.cos(dy - (dy / 2) + clock / 10) * (math.max(screenshake, 50)) / 100,
          c[math.random(#c)]
      )
  end
end

function draw_hud_energy()
  local ratio = 83 / ship.max_energy
  local higher_ratio = 90 / ship.max_energy
  local start_x = hud.energy.start_x
  local start_y = hud.energy.start_y

  local background_color = 7
  if (ship.energy_depleted) then	
      background_color = (7 + clock / 1.5) % 15
  end

  rect(start_x, start_y - 83, start_x + 1, 81, background_color)
  rect(start_x, start_y - 0.75 * 83 + 8, start_x + 3, 0.75 * 83 + 8 - 2, background_color)
  rect(start_x, start_y - 2, start_y - 0.5 * 83 + 8, 0.5 * 83 + 8 - 5, background_color)
  rect(start_x, start_y - 2, start_y - 0.25 * 83 + 8, 0.25 * 83 + 8 - 7, background_color)

  if (powerup ~= nil) then
      local powerup_color = 7
      if (powerup.in_use) then
          powerup_color = clock % 16
      end
      rect(start_x, start_y, start_x + 7, start_y + 7, powerup_color)

      draw(powerup)
  end
  for i = 1, 8 do
      local dy = i / 5
      local z = ratio
      local y = 83
      if (i > 6) then
          z = higher_ratio
          y = y + 7
      end

      local height = math.min(y * (0.25 * math.floor((i + 1) / 2)), ship.current_energy * z)

      line(
          start_x - i + 8,
          start_y - 2,
          start_x - i + 8,
          math.min(start_y - 2, start_y - height + 8) -
              math.cos(dy - (dy / 2) + clock / 10) * (math.max(screenshake, 50)) / 100,
          ({15, 8, 3, 1})[1 + math.floor((i - 1) / 2)]
      )
  end
end

function draw_hud_shots()
  local ratio = 83 / ship.max_consecutive_shots
  local max_height = ship.max_consecutive_shots * ratio
  local start_x = 127 + 112
  local start_y = 127 + 8

  rect(start_x, start_y, start_x - 1, start_y - 83 + 2, 7)
  rect(start_x - 2, start_y - 0.25 * 83 - 1, start_x - 3, start_y - 83 + 2, 7)
  rect(start_x - 4, start_y - 0.5 * 83 - 1, start_x - 5, start_y - 83 + 2, 7)
  rect(start_x - 6, start_y - 0.75 * 83 - 1, start_x - 7, start_y - 83 + 2, 7)

  rect(start_x, start_y - max_height, start_x - 7, start_y - max_height - 7, 7)

  local current_height = math.min(max_height, ship.current_shots * ratio - 7.5)

  local colors = {7, 10, 9, 8}

  rect(
      start_x,
      start_y - max_height,
      start_x - 7,
      start_y - max_height + 1 - (upgrades[ship.weapon] % 7),
      (upgrades[ship.weapon] / 7) + clock % 2
  )
  draw({spr = special_offers[ship.weapon - 3].spr, pos = {x = start_x - 2, y = start_y - max_height - 2}}, 0.8)

  for i = 1, 8 do
      local dy = i / 5
      local limit = (math.floor((i - 1) / 2) * 0.25 * 83) + 3
      if (current_height > limit) then
          line(
              start_x - i + 1,
              start_y - 8 + 10 - limit,
              start_x - i + 1,
              math.max(
                  start_y - 8 + 10 - max_height,
                  start_y - 8 + 10 - current_height -
                      math.cos(dy - (dy / 2) + clock / 10) * (math.max(screenshake, 50)) / 100
              ),
              colors[1 + math.floor((i - 1) / 2)]
          )
      end
  end
end

function draw_stars(layer)
  local x = star_layers[layer].pos.x % 120
  local y = star_layers[layer].pos.y % 78

  local a = star_layers[layer].sprite_x
  local b = star_layers[layer].sprite_y

  -- 2  1  12 11
  -- 3  A  D  10
  -- 4  B  C  9
  -- 5  6  7  8
  map(a, b, 8, 8, x, y - 78) --1
  map(a, b, 8, 8, x - 120, y - 78) --2
  map(a, b, 8, 8, x - 120, y) --3
  map(a, b, 8, 8, x, y) --A

  map(a, b, 8, 8,x - 120, y + 78) --4
  map(a, b, 8, 8,x - 120, y + 78 + 78) --5
  map(a, b, 8, 8,x, y + 78 + 78) --6
  map(a, b, 8, 8,x, y + 78) --B

  map(a, b, 8, 8,x + 120, y + 78 + 78) --7
  map(a, b, 8, 8,x + 120 + 120, y + 78 + 78) --8
  map(a, b, 8, 8,x + 120 + 120, y + 78) --9
  map(a, b, 8, 8,x + 120, y + 78) --C

  map(a, b, 8, 8,x + 120 + 120, y) --10
  map(a, b, 8, 8,x + 120 + 120, y - 78) --11
  map(a, b, 8, 8,x + 120, y - 78) --12
  map(a, b, 8, 8,x + 120, y) --D
end

function draw(drawable, scale)
  local base = drawable.spr.frame * drawable.spr.size_x
  local sprite = drawable.spr.start + math.floor(base / 16) * (16 * (drawable.spr.size_y - 1)) + base

  if (scale == nil) then
      scale = drawable.spr.scale
  end

  local flip = 0
  if (drawable.spr.flip_x and drawable.spr.flip_y) then
      flip = 3
  elseif (drawable.spr.flip_x) then
      flip = 1
  elseif (drawable.spr.flip_y) then
      flip = 2
  else
      flip = 0
  end

  spr(
      sprite,
      drawable.pos.x - (drawable.spr.size_x * 8 * scale / 2),
      drawable.pos.y - (drawable.spr.size_y * 8 * scale / 2),
      0,
      scale,
      flip,
      0,
      drawable.spr.size_x,
      drawable.spr.size_y
  )
end

function make_text(content, pos, ttl, type, color)
  local text = {pos = {x = pos.x, y = pos.y}, ttl = ttl, type = type}

  if (type == TEXT_TYPE_SIGNAL) then
      text.signal = content
      text.played = false
      text.current = 1
      text.color = color or 7
  elseif (type == TEXT_TYPE_POPUP) then
      text.content = content
  end

  return text
end
-- <TILES>
-- 000:000000220000244400003444000244440024444400223334022233340333333a
-- 001:3000000042000000a3000000aa3000004aa3000044a40000ff444000ffc44000
-- 002:0000002400000034000024440024444400224444032234440422234f02222fff
-- 003:200000004ff0000044f30000a4f20000aaa30000aaa300004aa42000c4442000
-- 004:000000000000000200024444002244440232244a042244440422aff40432fff4
-- 005:000000004a30000044ff000044cf0000aaff0000aaa40000aaa30000aa440000
-- 006:000000000000000000002444002224440022344a0223444a022aff4a03afff4a
-- 007:000000000342000044fa000044ff300044cf3000aaff3000aaaf2000aa330000
-- 008:00000000000000000000244400023444003444aa02aaf4aa03aafaaa03affaaa
-- 009:00000000000000004444300044faa00044ff300044fff000affff000a4ff4000
-- 010:00000000000000000000244402344444033a4aa403aa3aa403a43aaa02a4aaaa
-- 011:000000000000000042000000443000004fa4a200ffffa300ffff3200ffff4000
-- 012:0000000000000000002344440233434402344a4402a3aa3402333a3f0244aaaa
-- 013:0000000000000000432000004432000044430000ffa42000fffaa200fff3a200
-- 014:0000000000022000002344440023434400333444003333cf024333ff0243a3af
-- 015:000000000000000044200000443200004443000044432000fc4a2000ffaa0000
-- 016:0044333a00044aff0002a3ff0000024400000000000000000000000000000000
-- 017:fffa0000ffa00000f42000000000000000000000000000000000000000000000
-- 018:003a3fff0003afff00003ffc0000332300000000000000000000000000000000
-- 019:f4442000ffa30000f32200002200000000000000000000000000000000000000
-- 020:003affff003affff0003afaa0000202300000000000000000000000000000000
-- 021:4444000044440000aa3000000000000000000000000000000000000000000000
-- 022:03afffc4004afff400033aaa0000022300000000000000000000000000000000
-- 023:4443000044a20000444000002200000000000000000000000000000000000000
-- 024:023af444002aa444000033440000022300000000000000000000000000000000
-- 025:3434000043a30000aa3300004440000000000000000000000000000000000000
-- 026:003443a400244443000244a30000023300000000000000000000000000000000
-- 027:ffff20003344000034f30000faa0000042000000000000000000000000000000
-- 028:0044434f00444333000233330000023400000003000000000000000000000000
-- 029:ffff00004ff40000444400004f30000043000000000000000000000000000000
-- 030:02443faf0023333f00003334000003440000003a000000000000000000000000
-- 031:fa3a0000ff4a000044a20000ff300000a3000000000000000000000000000000
-- 032:000000000000024000002444000334440022244400322ff404323fff0424afff
-- 033:00000000000000004200000044300000444430004433f000443330004aa3f000
-- 034:0000000000000004000034440022444400334444022ff444023aff44003aa44a
-- 035:00000000300000004320000043300000443400004434200043334000a333f000
-- 036:00000000000000400002334400234444003ff444023f4444023f4444023244a3
-- 037:00000000432000004330000043320000443320004433400033344000333f4000
-- 038:000000000000024000224344003a444403af444403af444403344444032aa433
-- 039:000000000000000044a3000043330000433a2000433a30004333400033343000
-- 040:0000000000030020023a444402aa444402a444440044444403aa444403aaa333
-- 041:00000000000000004440000044aa00003333f0003333f000333ff00033333000
-- 042:000033000023a440003a44440244444423444444333444440332344300223333
-- 043:00000000200000004300000044400000444a0000333f0000333af00033fff000
-- 044:00002f200003a444004a44440344444402344444032244430023343300233333
-- 045:0000000020000000aa2000004442000044f4000034ff000033af0000333f0000
-- 046:000002ff0003a344002444440023444400224444002344330023333302233333
-- 047:0000000020000000a32000004aa400004444000044f400003fff20003aff0000
-- 048:00223ff300022afa000234f400000444000004fa000000000000000000000000
-- 049:aa3a0000aaa3000043a30000f340000034000000000000000000000000000000
-- 050:003aa3aa0003a3aa0004443300033aa3000023a3000000000000000000000000
-- 051:a3332000333a00003ff30000f330000042000000000000000000000000000000
-- 052:00323aaa00343a33000433330003333f00003334000000200000000000000000
-- 053:333f0000333a0000faf00000fa30000000000000000000000000000000000000
-- 054:033aaaa3004a33330033233300033aaa00000443000000000000000000000000
-- 055:33f4000033f30000ff300000f300000030000000000000000000000000000000
-- 056:02333333003223330032333a000233aa00000220000000000000000000000000
-- 057:34440000f4400000ff3000002200000000000000000000000000000000000000
-- 058:00233333002233a40033afa400023a3300000000000000000000000000000000
-- 059:33fa300044440000440200003200000000000000000000000000000000000000
-- 060:00233333003af4440003a4440002033a00000002000000000000000000000000
-- 061:3fff000043a40000444000003200000000000000000000000000000000000000
-- 062:023333330034443a0023a3440000233300000020000000000000000000000000
-- 063:3aff0000fff30000343000002200000000000000000000000000000000000000
-- 064:000000000000000500000035000003bb00ffa5ab00003bbb00000af000000300
-- 065:00000000b5000000bb000000b5a0000053aaaa00bbba20000fa5000000a00000
-- 066:0000000000000000002fa323000053ab00055bb30082f55b0820005a0000028a
-- 067:000000000005200035bbb000bbba0000fba30000bba00000a230000000000000
-- 068:00000020000000a3000053b522825bbb00005afb8a80abbb0222fbfa00000000
-- 069:0000000000000000a2000000bffbb500bbbbbb20af3000000000000000000000
-- 070:000000000000aa05020002530f803a3b0023bbbb000aafaa0000000000000000
-- 071:0000000020a000003ba00000bba00000bfbb0000abbbb0000005200000000000
-- 072:0000000000000300002035bb000fa5bb0000a35b0000033b0000000500000000
-- 073:0000000000a000005efa0200bbbaa200bbaf0000bba00000b500000020000000
-- 074:0000000000000f0000000f520000035b000035fb00053bba0002b00000000000
-- 075:00000000508a0000aba00000b3fa08a0bbbbaa00afafa0000000000000000000
-- 076:00000000000000000000002a00555ffb005bbbbb000003fa0000000000000000
-- 077:020000002f0000005eab0000bbbb08a2bffb0000bbbf08883a5f230000000000
-- 078:00000000000250000005bba5000035bb0000235300000ab500000f3300000000
-- 079:0000000000000000332aa300b3a53000abbbb000bb5f2800bb000220a2300000
-- 080:00000000000e000000989000000e000000080000000000000000000000000000
-- 081:0000000000080000009e900000686000000e0000000000000000000000000000
-- 082:0000000000000000000908000000e00000080900000000000000000000000000
-- 083:000000000000000000090e0000068000000e6900000000000000000000000000
-- 084:00000000000000000000000000000900008e8e80000009000000000000000000
-- 085:0000000000000000000000000000690000e8e8e0000069000000000000000000
-- 086:000000000000000000000000000e09000000800000090e000000000000000000
-- 087:000000000000000000000000000869000006e000000908000000000000000000
-- 088:0000000000000000000e000000080000009e9000000800000000000000000000
-- 089:000000000000000000080000006e600000989000000e00000000000000000000
-- 090:0000000000000000000000000090e0000008000000e090000000000000000000
-- 091:00000000000000000000000000968000000e6000008090000000000000000000
-- 092:000000000000000000000000009000000e8e8e00009000000000000000000000
-- 093:0000000000000000000000000096000008e8e800009600000000000000000000
-- 094:000000000000000000809000000e000000908000000000000000000000000000
-- 095:000000000000000000e09000000860000096e000000000000000000000000000
-- 096:0000000000000f0000000000000000000000000000000000000000000f000000
-- 097:00000000000000000000000000f0000000000000000000000000000000000000
-- 098:f000000000000000000000000000000000000000000030000000000000000000
-- 099:00000000000000000000000000f00000000000f000000000000000000000f000
-- 100:000000f0000000000000000000000000000000000000000000f0000000000000
-- 101:0000000000f00000000000000000000000000000000000000000000000000000
-- 102:00000000000f0040040f0000000040f0004040000f000000000000400000400f
-- 103:f00000044f0004000000000000004000400f40000000040000000000f0000004
-- 104:0000004000000400000000000000f0400000000000f000000000004000000000
-- 105:000000400000000000f0000000000004000000000000000000000000f0000000
-- 106:f000000000000000000000000000000000000000000000000000000000000000
-- 107:00000000000e04000f9944000046440004449f00048ff6000000f00000000000
-- 108:440404004ff40ff044f00444006999040069e940446994400000004440000004
-- 109:400006604466060feee60fff00e6eee0666ee00e0ee0066f0f00006fff000066
-- 110:460000660644404400000004004e6004600f3e000400f0004400004400040066
-- 111:ff4000660000000644000300f000e3f0f00ef0f0f30000f00300000000040004
-- 112:0000000333000003000000004000000000000000300000303300003fff0000ff
-- 113:3300000030000030000000300000000000000000000000000000000300000033
-- 114:0000000000000000000000000008f000000fe000000000000000000000000000
-- 115:00000000060000f000f00800000000000000000000f00f000f0000f000000000
-- 116:f000000e000000000000000000000000000000000000000000000000f0000006
-- 117:0000000000000000000000000300000000000000000000000000000000000000
-- 118:0000000000000000000000c00000000000000000000000000000000000000000
-- 119:0000000000000000000000000008800000008000000000000000000000000000
-- 120:000000000000000000080000000ff80000800000000800000000000000000000
-- 121:00000000000000000000000000f00f00000000000800f0800000080000000000
-- 122:0000000000000080000000000f000000000000f000000000000f000000000000
-- 123:000000000ff00ff00f0000f000000000000000000f0000f00ff00ff000000000
-- 124:0000000000099000009ee90009e99e900e9669e0096006900600006000000000
-- 125:00000000000ee00000e99e000e9669e009699690069009600900009000000000
-- 126:00000000000990000096690009699690069ee96009e00e900e0000e000000000
-- 127:000000000006600000699600069ee96009e99e900e9009e00900009000000000
-- 128:00ee30000e9ee0003e99e9003e999e0009949e0009999e900049ee9000090000
-- 129:000e300000094000004940000049400000494000004940000049400000090000
-- 130:0009ee00009eee9004ee9e9009ee9e900eee9e900eee9e0000eee900000e3000
-- 131:0049900009eeee309ee9eee0eee9eee9eee9eee90ee9eee00eeeee0000e9e000
-- 132:09e900000eeee0003ee9e9003ee9ee000ee9ee000ee9ee9009eeee0000990000
-- 133:0009000000494000004940000049400000494000004940000049400000090000
-- 134:0009e90000ee990009e949000e9999003ee99e000e999e000e99990000099000
-- 135:004940004eeeee30ee999e90eeee99e00e9999e0099e9ee000999e0000990000
-- 136:00f8ff0000f0ff0000f8f80000f8f80000fff80000fff80000fff80000f8ff00
-- 137:00000fff0000fff8000fff8f000ff8ff00ffff0008f8f0008ffff000ffff0000
-- 138:0000000000000000ffffff0f80ff8088ffffffff8088ff800000000000000000
-- 139:f8f00000ff8f0000f8fff0000f8fff0000ff8ff0000f8fff0000fff800000fff
-- 144:000000000000000000000000000000000000000000000000000000330000003f
-- 145:00000000000000000000000000000000000000000000000033000000f3000000
-- 146:0000000000000000000000000000000000000000000000030000003f000003f0
-- 147:000000000000000000000000000000000000000030000000f30000000f300000
-- 148:0000000000000000000000000000003300003000000300f000000f0000300f06
-- 149:00000000000000003000000003300000003003000f00000000f0300060f00000
-- 150:00330000033f060033f0660030f0360030f33600000300000000009e00000098
-- 151:00f0003300ff33060000f3060000f03600000f66006600000996000089060000
-- 152:0000000000000000000ee00600ee033000e00000000000000300000000000008
-- 153:00000000000000000000ee0000000ee0000030e0000000000000003000006030
-- 154:000000000f000000ff003338f0000008f000000800060008000000080033000f
-- 155:000000003330ff0000000ff0000990f000009000000003000000033000000300
-- 156:90000008000000080000000f0000000f00000000000000000000000000000000
-- 157:0000009900000000000000000000000000000000000000000000000000000000
-- 158:0000000800000000000000000000000000000000000000000000000000000000
-- 160:0000003f00000033000000000000000000000000000000000000000000000000
-- 161:f300000033000000000000000000000000000000000000000000000000000000
-- 162:000003f00000003f000000030000000000000000000000000000000000000000
-- 163:0f300000f3000000300000000000000000000000000000000000000000000000
-- 164:000300660000ff0600300f0000033ff000000000000033000000000300000000
-- 165:6000f030000ff30000ff03000000300030030000000000000000000000000000
-- 166:000030680000030600f0033630f0000033f0000003ff0000003ff00000000000
-- 167:8009900f0099000f000600ff00660ff00660033000000300000f300300ff0033
-- 168:ee0000880ee00008030000000300000003360000000600000000e0000000ee00
-- 169:8000000000000000000000330000003000660000000000e0003300e000300ee0
-- 170:000888ff0000000f09000008090300080f0330080ff0000800ff000000000000
-- 171:f88880000000000000000060000000000030000003300ff00090ff0000000000
-- 172:88ff00000000000000000000000000000000000f0000000f0000000830000008
-- 173:0000ff880000000000000000000000000000000000000000000000000000000f
-- 174:8000000000000000000000000000000000000000000000000000000000000008
-- 175:0000000800000000000000000000000000000000000000000000000000000000
-- 176:0000000006606600666f666006fff600006f6000000600000000000000000000
-- 177:0660066066666666666ff6666ffffff66ffffff6066ff6600066660000000000
-- 178:00000880000088f000088f000088f00000088f000088f000088f000008800000
-- 179:0000000000000800000080000008000000008000000800000080000000000000
-- 180:0000f0000000f0000000f0000000f0000000f0000000f0000000f0000000f000
-- 181:0000f0000000f0000000f000000fcf00000fff000000f0000000f0000000f000
-- 182:0000f0000000f000000fff00000fbf00000f6f00000fff000000f0000000f000
-- 183:0000f000000f8f00000fef00000fef00000f8f00000f8f00000f8f000000f000
-- 184:0000f0000000f000000fff00000f9f00000f9f00000fff000000f0000000f000
-- 185:0000f0000000f0000000f000000fff00000fcf000000f0000000f0000000f000
-- 186:000ee00000e00e000e0000e0e000000e000ee00000e00e000e0000e0e000000e
-- 187:00e00e000e0000e0e000000e000ee00000e00e000e0000e0e000000e000ee000
-- 188:0e0000e0e000000e000ee00000e00e000e0000e0e000000e000ee00000e00e00
-- 189:e000000e000ee00000e00e000e0000e0e000000e000ee00000e00e000e0000e0
-- </TILES>

-- <MAP>
-- 000:ffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:ffffffffffffff57ff16ffffffffffffffffff16ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:ffff16ffffffffffffffff06ffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:ffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:ffffff57ffffffff5767ffffff57ffffffffffff67ffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:ffffffffffffffffffffffffffffffffffffffff57ffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:ff06ffffffffff16ffffffffffffffffffffffffff06ffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:ffffff57ffffffffffffff57ffff16ffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:ffffffffffffffffffffffffffffffffffffffffffffffa6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <PALETTE>
-- 000:0000001d2b537e255383769cab5236008751ff004d5f574f29adffffa300c2c3c700e436ffccaaff77a8ffec27fff1e8
-- </PALETTE>

-- <COVER>
-- 000:4ca000007494648393160f00880077000012ffb0e45445353414055423e2033010000000129f40402000ff00c2000000000f00880078f575f40000003867c9007815ff1f8eba2563e752352c3c7cd1b235ffccaaff778a004e6392daffff3a00ff00d4ffce7200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080ff0010408181000804288031a24586071a3c18d012e1c7841b2a5cb85072264481152e6cf80234e741042b46081072126001060b566c8870b321c692096ecce8e2f5ac4b92153ed48904b0efc58c3d62dc890417acce98479a8c7a05b269c9a355566cb9a21962cc975582cceaa5d3e7d0b34d3a753a53d7a65ead5fa63c1b13dda857a15bead528453fa053bd69921d7b171ea555a0657afce958b6e9d3cb759295eab330b2e6be29eeddbcb13f2555b08ffe6dc9f5f56954cd97f2f5fb88db636ab863273d3d2a1c6568c8913218ad8753b9cf8c617f5cedeb38b846c2cb8f04dd52d2f345e6cb9b3f7e0d5422729545272d4a8a3ab6fdecd38f4769293b6cff5ac96b077f3f8e3d76e9e28fce0e9809536766eaebebd7fece7c38e1f1b7f37c2f4f5847bdd74028430617fd518a0e28c0ea78c538016481162821658616d741e58a1e680d568c1e78026d6e16884269812d88626a8a2a3482ea8e2ea8d2eb82329813ec863e6853ed8a3a4893ee8e3e28d3ef824ad714e0964e9754e19a464794e29e4a17d4e39252e615e4965ad555e59a5a473d53720c37f56d57061816a375624536a2495e69c6264b66b907e34f66c947224376d957ed9876c9a7ee9e7ef908e54504106081018e64962e93861a7863ab051a3511040c107083a69214096942925a79e1a58e0a3825a35d0ad960af928a2a6944a28898a3ada6d67a28ffa0aae55aee91baca500da5b6e9208ca4215a38a4a29eeacd94a682f8dbeca2000b5080b80020d66ea01a1038e2b766185823b49e6bbda3b0de599c65b7c21860c2b8be8b8da10ad27bdda4afca597b6ea7daa75003b3b2ab40efa7045bbc2bbeda59421ea9b61040a0cb82eb7f9ebcf2bb70cfb2561a292eadb22c7e53bcfa8bc0aeb9a27b1cabbfde395e63c4082bdbad76080b9715c816fbb1f6bd1310fee24f1bf8df68a7086a7fd6a92bac9ed45beadbdc6cca0d7c3feb8df2bc521fc329d5a37ac04694f3feb0a2cc3332455fe86d6aabc6eb2cedc3b23899a1c20b0d90d5da329c2961d8e5fa9ca5ba43a716b8d2b29d65b19afa0040094b066a20cbffd9ea8d600dd4099da368c31748e7b281f28a1831e4831b07a0e30d3e093b9297004975ea5e5e99b6e6527ee93e90a78e47e8e4a74ee879890ceabaf376af9e697ae0b7b9fafce756de6bf498b7eef46cc30cfe0c77ecbb09eb30ffbb0f3cbf85cb1f8c72fa3e3ba08206cf1fc1aadbd910821886db170db4f3d73fd6e00b0c2070c00429ab7379e8044f3df000e7b92088f3ef2b6e7d9dd7bf4473a5ea9f22f8f1080b40100a49ee7fdb25d1061030016110e467b916930f554cb5f97f8975aacb9006103caff930538d0c10a401f723280617446309c0630704224205a0f92404a0eea41852cc02705347ebeb52ec22d2c0e93f200c0060084a7830102601ffd78ed1945202f6c8a8a4e09a76bbe1a01788c34580113a840172201da8254f1e41d98054a2a51795e44d95d5698eeb62241fa8854488613a824c726b1312654d22115e8144e12011c8c00204f0917a4cf0610767374a3ea17a8344e26b17b8374832b1de857c73612d0016c400f11a246c7f5386588e1c2e51719a64142229e845ca22729b858c24230a0509cd320be68e09a4ee09740924598a6c8e7471eb27a54d2956afaf8cebf3ed2b149b44553b859daca5ae0f79883c55ed869db4b52231249c291252d89c448d530a10519b62633007dcb8473702fdc484833b9bd4c411ae123eca88b27673e4d62142c9adc47273dd92fc97673fb95ec772d3dd90ffe4872e33e971957a53bc97f4c66c37b95f4e7ec35f96f4d7ac351a8fc5827352a80dc7aa39a956467214bd99fc48af391a01548e246f90e4a8a9452a105c8a52d15cfc09a83f1ad2d286f356a31548004f4a12de86d3786a2d76e1940ae3df110538ab3a1a215f6464d3aec829a3b3e4924c9a4018a2540aa25d8a65a61255d09465bc6d3d6ae6be9ae45e6d048d5065e4d655ca16d488857ca45d6ba957da233c866f0679653b2b5300965cbe555dad65baae57fa075fb2e55fa3652ce06fba28d780917ea7a39aeb5fba97d3b6f5fea8853cee5fea78dba65a2faf75cca265eaa2ade9d6283e8dbceb5b0bc6dbc6a653b7adfbe6653bc757ba5595b5a55dffa5d04b05aa3556954b2a5c215909a64719f659a545cd217f5589480d07d7a8c51ea1798b051ffd544ab100aee35cabc3d66a1f2773e3ff577710309feeffaab2d50fed60cb4e5cee771dbdd558ca73dbced6f2973cb1ed6feb73eaad50e9de2eb3fdae6f71cb5e5ff2083dbe01ae6083126066fef771c2fdaf25469bd8a4e2f7dab41650fd790c8064fe2833c409007589eb5f5efe763fbfb3eead753cdfde079710cc26ceaa83eb82648c989ebaed5175836c38b7e24756401ed1fb8a7ce3eedae85149c5c3519b9304e027a829c81170830200e4e18449d1215672b595ac3568276959cf11fda59f9cf5628c591bcb5ef2f395bc55603f991bca5e63f699e8bc92521f006ccd6682bb91ccc6e927699ec26e13f595dc87683f64ab790840c4f8ec56ed37e9fccf6ef3fa9fec25ea3f3a50d71d8e51a7a78665372401de8ee330a91df96f4b8a92d8196f16a94d62235f6715d5220e939bd7cae65fc9fa9e08357ca1443be70c30a106b61daf9c7d35a1043067d3c6b5fda934308d5ffe87dbae3632b99d6a676f7845d0cb080000b3
-- </COVER>

