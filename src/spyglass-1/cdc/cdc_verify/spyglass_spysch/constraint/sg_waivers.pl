################################################################################
#This is an internally genertaed by spyglass to populate Waiver Info for Reports
#Note:Spyglass does not support any perl routine like "spyDecompileWaiverInfo"
#     The routine is purely for internal usage of spyglass
################################################################################


use SpyGlass;

spyClearWaiverHashInPerl(0);

spyComputeWaivedViolCount("totalWaivedViolationCount"=>'44',
                          "totalGeneratedCount"=>'0',
                          "totalReportCount"=>'0'
                         );

spyDecompileWaiverInfo("waive_cmd_id"=>'1',
                       "waiverCmd"=>'q%waive  -rule "Ac_datahold01a" -comment "Created by ameybiniwale on 11-Sep-2026 22:57:45"%',
                       "-rule"=>'"Ac_datahold01a"',
                       "-comment"=>'"Created by ameybiniwale on 11-Sep-2026 22:57:45"',
                       "violations_waived"=>'405 406 407 408 409 410 411 412 413 414 415 416 417 418 419 420 421 422',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./spyglass-1/cdc/cdc_verify/spyglass-1_waiver_file.awl"',
                       "waiverline"=>'1'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'2',
                       "waiverCmd"=>'q%waive  -rule "Ac_conv01" -comment "Created by ameybiniwale on 11-Sep-2026 22:57:56"%',
                       "-rule"=>'"Ac_conv01"',
                       "-comment"=>'"Created by ameybiniwale on 11-Sep-2026 22:57:56"',
                       "violations_waived"=>'382 384 386 388 391 393 396 398',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./spyglass-1/cdc/cdc_verify/spyglass-1_waiver_file.awl"',
                       "waiverline"=>'2'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'3',
                       "waiverCmd"=>'q%waive  -rule "Ac_cdc01a" -comment "Created by ameybiniwale on 11-Sep-2026 22:58:58"%',
                       "-rule"=>'"Ac_cdc01a"',
                       "-comment"=>'"Created by ameybiniwale on 11-Sep-2026 22:58:58"',
                       "violations_waived"=>'399 400 401 402 403 404',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./spyglass-1/cdc/cdc_verify/spyglass-1_waiver_file.awl"',
                       "waiverline"=>'3'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'4',
                       "waiverCmd"=>'q%waive  -rule "Ac_glitch03" -comment "Created by ameybiniwale on 11-Sep-2026 22:59:33"%',
                       "-rule"=>'"Ac_glitch03"',
                       "-comment"=>'"Created by ameybiniwale on 11-Sep-2026 22:59:33"',
                       "violations_waived"=>'176 178 180 182',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./spyglass-1/cdc/cdc_verify/spyglass-1_waiver_file.awl"',
                       "waiverline"=>'4'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'5',
                       "waiverCmd"=>'q%waive  -rule "Ac_coherency06" -comment "Created by ameybiniwale on 11-Sep-2026 23:00:18"%',
                       "-rule"=>'"Ac_coherency06"',
                       "-comment"=>'"Created by ameybiniwale on 11-Sep-2026 23:00:18"',
                       "violations_waived"=>'143 148 153 156 159',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./spyglass-1/cdc/cdc_verify/spyglass-1_waiver_file.awl"',
                       "waiverline"=>'5'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'6',
                       "waiverCmd"=>'q%waive  -rule "Ac_unsync01" -comment "Created by ameybiniwale on 11-Sep-2026 23:00:58"%',
                       "-rule"=>'"Ac_unsync01"',
                       "-comment"=>'"Created by ameybiniwale on 11-Sep-2026 23:00:58"',
                       "violations_waived"=>'53 56 58',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./spyglass-1/cdc/cdc_verify/spyglass-1_waiver_file.awl"',
                       "waiverline"=>'6'
                      );

spyWaiversDataCount("totalWaivers"=>'6',
"totalWaiversApplied"=>'6',
"totalWaiversWithRegExp"=>'0',
"totalWaiversWithRuleSpecified"=>'6',
"totalWaiversWithIpSpecified"=>'0',
"totalWaiversWithFileLine"=>'0',
                         );

spyProhibitWaiverRules(                         );

spySetWaivedViolationNumberHash("");

1;
