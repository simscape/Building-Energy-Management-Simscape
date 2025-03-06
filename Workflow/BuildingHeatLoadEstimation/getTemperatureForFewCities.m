% Copyright 2025 The MathWorks, Inc.

monthlyTavg.Stockholm = simscape.Value([269,275; 268 271; 270 274; ... % Q1 months (min,max)
                                        274 279; 279 284; 283 288; ... % Q2 months (min,max)
                                        286 291; 285 290; 281 286; ... % Q3 months (min,max)
                                        276 280; 274 276; 270 273],... % Q4 months (min,max)
                                        "K");

monthlyTavg.Vienna = simscape.Value([269,275; 271 277; 273 282; ... % Q1 months (min,max)
                                     277 287; 282 293; 286 296; ... % Q2 months (min,max)
                                     287 297; 287 297; 283 292; ... % Q3 months (min,max)
                                     279 287; 275 280; 270 275],... % Q4 months (min,max)
                                     "K");

monthlyTavg.Zurich = simscape.Value([272,276; 272 278; 275 283; ... % Q1 months (min,max)
                                     278 287; 282 292; 286 295; ... % Q2 months (min,max)
                                     287 297; 284 292; 280 287; ... % Q3 months (min,max)
                                     276 281; 276 281; 272 277],... % Q4 months (min,max)
                                     "K");

