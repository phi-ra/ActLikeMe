breed [people a-person] ;; specify agentset

globals [
  exp-risk

  max-sick-proportion
  max-hospitalization
  max-hospital-occupation
  max-healthcare-ratio

  act-infect-people
  act-hosp-people
  act-immune-people
  act-dead-people
  act-sick-people
  act-required-hosp
]

turtles-own [
  infected?
  infected-on
  sick?
  hospital?
  immune?
  dead?
  highrisk?
]


to setup
  clear-all
                                        ;; Setup of population, all people start as healthy and outside of the hospital
  create-people number-of-people [
    setxy random-xcor random-ycor
    set infected? false
    set sick? false
    set immune? false
    set dead? false
    set highrisk? false
    set hospital? false
    set shape "person"
  ]
                                        ;; Setup of network, people are connected with the specified number of people and "clustered" together
  repeat count people * avg-relationships-per-person [
    ask one-of people [
      create-link-with min-one-of other people with [not member? self [link-neighbors] of myself] [distance myself]
    ]
  ]

  setup-experiment
end


to setup-experiment
                                        ;; Reset all ticks and set all counters to zero
  reset-ticks
  set max-sick-proportion 0
  set max-hospitalization 0
  set max-hospital-occupation 0
  set max-healthcare-ratio 0

  set act-dead-people 0
  set act-infect-people 0
  set act-hosp-people 0
  set act-immune-people 0
  set act-sick-people 0
  set act-required-hosp 0

  ask people [
    set infected? false
    set immune? false
    set sick? false
    set hospital? false
    set infected-on 0
    set dead? false
    set highrisk? false
    set color green
  ]

  ask n-of init-affected people [
    set infected? true
    set color 25
    set infected-on ticks
  ]
end

to go
                                        ;; Finish simulation once no more people are affected
  if not any? turtles with [sick?] and not any? turtles with [infected?] [
    stop
  ]
  ask people with [(infected? or sick?) and not hospital? and not dead?] [
                                        ;; introduce sampling from distribution here
    ask my-links with [random 100 < probability-of-interaction] [
      if random 100 < probability-of-infection [
        ask other-end [
          if not infected? and not immune? and not sick? and not dead? [
            set infected? true
            set infected-on ticks
            set color 45
          ]
        ]
      ]
    ]
  ]

                                        ;; sick people that require hospitalisation and are in hospital
                                        ;; have a given probability to die
  ask people with [(sick?) and hospital?] [
    if random 100 < probability-of-death [
      set dead? true
      set sick? false
      set hospital? false
      set immune? true
      set color black
    ]
  ]
                                        ;; sick people that require hospitalization but are not in
                                        ;; a hospital have a higher chance to die
  ask people with [ sick? and highrisk? ] [
    if random 100 < (probability-of-death * death-outside-hosp-factor) [
      set dead? true
      set sick? false
      set immune? true
      set color black
    ]
  ]

  let current-dead-relative count people with [dead?] / number-of-people
  let current-infection count people with [infected? or sick?] / number-of-people

  let cur-hospital-occupation count people with [hospital?]
  let cur-require-hospitalization floor ((count people with [sick?] * require-hospitalization-pcnt) / 100)
  let cur-healthcare-ratio cur-require-hospitalization / hospital-beds
  let cur-sick-people count people with [sick?] / number-of-people

  set max-sick-proportion max (list max-sick-proportion current-infection )
  set max-hospitalization max (list max-hospitalization cur-require-hospitalization )
  set max-hospital-occupation max (list max-hospital-occupation cur-hospital-occupation)
  set max-healthcare-ratio max ( list max-healthcare-ratio cur-healthcare-ratio )

  set act-infect-people current-infection
  set act-hosp-people cur-hospital-occupation / count people
  set act-dead-people current-dead-relative
  set act-sick-people cur-sick-people
  set act-required-hosp cur-require-hospitalization / number-of-people

  ; At the end of incubation period, person turns sick with a probability
  ask people with [infected? and (ticks - infected-on) > incubation-period] [
    set infected? false
    set sick? true
    set color red
  ]
  ; Recovery gives infinite immunity
  ask people with [(sick? and (ticks - infected-on) >  (recovery-time + incubation-period)) and not dead?] [
    set sick? false
    set immune? true
    set hospital? false
    set color gray
  ]

  let current-immune count people with [immune? ] / count people
  set act-immune-people current-immune

                                        ;; A percentage of users require hospitalization but once the system is overloaded
                                        ;; they will not be admitted to the hospital, and will get the badge "highrisk"
                                        ;; which in turn will affect their chance of survival

  let cur-to-hospital 0
  if (cur-require-hospitalization - cur-hospital-occupation) > 0 [
    set cur-to-hospital (cur-require-hospitalization - cur-hospital-occupation)
  ]
  ask n-of cur-to-hospital people with [sick?] [
    ifelse cur-hospital-occupation < hospital-beds [
      set hospital? true
      set color lime
      set cur-hospital-occupation cur-hospital-occupation + 1
    ] [
      set hospital? false
      set highrisk? true
      set color 45
    ]
  ]

  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
605
130
1123
649
-1
-1
15.455
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

SLIDER
15
335
220
368
probability-of-interaction
probability-of-interaction
1
100
40.0
1
1
NIL
HORIZONTAL

BUTTON
15
170
220
203
Set up new Network
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
15
415
220
448
Run Simulation
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
240
170
465
203
avg-relationships-per-person
avg-relationships-per-person
1
30
5.0
1
1
NIL
HORIZONTAL

SLIDER
240
130
465
163
number-of-people
number-of-people
3
1000
497.0
1
1
NIL
HORIZONTAL

PLOT
15
510
595
695
Infected
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"infected" 1.0 0 -8330359 true "" "plot act-infect-people"
"hospital" 1.0 0 -2674135 true "" "plot act-hosp-people * 1"
"immune" 1.0 0 -7500403 true "" "plot act-immune-people * 1"
"dead" 1.0 0 -16645118 true "" "plot act-dead-people"
"requires_hospital" 1.0 0 -955883 true "" "plot act-required-hosp"

TEXTBOX
15
120
45
175
1.
40
0.0
1

BUTTON
15
375
220
408
Set up new Simulation
setup-experiment
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
50
145
200
163
Setup your network here.
11
0.0
1

TEXTBOX
10
225
35
271
2
40
0.0
1

TEXTBOX
45
230
220
341
You can run as many experiments as you want, and compare the results of reducing or increasing interactions between people, keeping everything else constant.
11
0.0
1

TEXTBOX
10
10
1110
125
    The purpose of this model is to show the effect of social isolation on the number of people infected at the same time. Like all models, it makes some assumptions: People have some number of social connections (friends, colleagues, etc.), and each day there is a probability that people will interact with people that they know. If someone is infected, there is a 15% chance that they will transmit their disease (\"probability of infection\" slider). Once they are infected (yellow colour), for 14 days (\"incubation period\" slider) they can infect others. After incubation period they get sick (red) and they remain contagious for 14 days (\"recovery time\" slider) after which they become immune (gray). 20% of sick persons (red) are assumed to need hospitalization. Hospitalized (green) persons are considered to be 100% isolated and do not infect others.\n    The risk of transmission and duration of illness are fictional, and do not reflect any characteristics of COVID-19. The purpose of this model is simply to show the impact on the height of the \"curve\" that social isolation can have.
12
0.0
1

SLIDER
240
230
465
263
probability-of-infection
probability-of-infection
1
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
240
310
465
343
incubation-period
incubation-period
1
20
7.0
1
1
NIL
HORIZONTAL

SLIDER
240
270
465
303
recovery-time
recovery-time
5
100
10.0
1
1
NIL
HORIZONTAL

MONITOR
480
130
535
175
Infected
count turtles with [infected?]
17
1
11

MONITOR
540
130
595
175
Sick
count turtles with [sick?]
17
1
11

MONITOR
480
180
535
225
Immune
count turtles with [immune?]
17
1
11

MONITOR
480
230
595
275
Max sick %
max-sick-proportion * 100
0
1
11

MONITOR
480
280
595
325
Max req. hosp.
max-hospitalization
0
1
11

MONITOR
540
180
595
225
Lucky
count turtles with [not sick? and not infected? and not immune?]
17
1
11

SLIDER
240
390
465
423
hospital-beds
hospital-beds
1
200
6.0
1
1
NIL
HORIZONTAL

MONITOR
480
380
595
425
Max hosp. occu. %
max-healthcare-ratio * 100
2
1
11

MONITOR
480
330
595
375
In hospital
count people with [hospital?]
17
1
11

SLIDER
240
350
465
383
require-hospitalization-pcnt
require-hospitalization-pcnt
1
100
10.0
1
1
NIL
HORIZONTAL

TEXTBOX
240
430
480
460
Maximum number of beds per 1000 people is 13 (Japan). UK has only 2.5
12
0.0
1

SLIDER
468
430
602
463
probability-of-death
probability-of-death
0
20
1.0
1
1
NIL
HORIZONTAL

CHOOSER
15
450
163
495
init-affected
init-affected
1 2 3
2

SLIDER
364
467
604
500
death-outside-hosp-factor
death-outside-hosp-factor
0
20
5.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?




Is isolation a good approach to limit COVID-19 impact on society?

## HOW IT WORKS



Every day (tick) agents randomly interact with their peers and thus (randomly) might get infected. Probability of interaction and getting infected in the case of interaction can be changed to model different social/viral behaviour.

## HOW TO USE IT

Set up number of persons in your model and number of links between them and click on "Set up new Network" button.

Set isolation slider to desired isolation level (how much one is trying to avoid contact with others) and click "Set up new Simulation" button. Once it is done, one sick person will be placed among healthy ones. Click "Run Simulation" and observe how everyone gets sick. After simulation completes, change isolation level, click again on "Set up new Simulation" followed by "Run".

## THINGS TO NOTICE

There are some heavy assumptions, DO NOT TAKE THEM FOR GRANTED. This is an illustrative model WITHOUT ANY CLAIM TO CORRESPOND TO REALITY. The model aims merely to show how social distancing can help keeping the number of people infected (and therefore presumably the number of occupied hospital beds) within the capacity of the healthcare system. 

## THINGS TO TRY
(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

We borrowed heavily from https://www.gisnet.lv/~marisn, unfortunately they did not provide contact details nor a licence. 
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
