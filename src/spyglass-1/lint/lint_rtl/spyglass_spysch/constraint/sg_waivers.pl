################################################################################
#This is an internally genertaed by spyglass to populate Waiver Info for Reports
#Note:Spyglass does not support any perl routine like "spyDecompileWaiverInfo"
#     The routine is purely for internal usage of spyglass
################################################################################


use SpyGlass;

spyClearWaiverHashInPerl(0);

spyComputeWaivedViolCount("totalWaivedViolationCount"=>'11',
                          "totalGeneratedCount"=>'13',
                          "totalReportCount"=>'2'
                         );

spyDecompileWaiverInfo("waive_cmd_id"=>'1',
                       "waiverCmd"=>'q%waive  -rule "STARC05-2.5.1.2" -comment "Created by ameybiniwale on 11-Sep-2026 22:18:47"%',
                       "-rule"=>'q%STARC05-2.5.1.2%',
                       "-comment"=>'"Created by ameybiniwale on 11-Sep-2026 22:18:47"',
                       "violations_waived"=>'41 42 43 44',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./spyglass-1/lint/lint_rtl/spyglass-1_waiver_file.awl"',
                       "waiverline"=>'1'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'2',
                       "waiverCmd"=>'q%waive  -rule "W415a" -comment "Created by ameybiniwale on 11-Sep-2026 22:20:48"%',
                       "-rule"=>'"W415a"',
                       "-comment"=>'"Created by ameybiniwale on 11-Sep-2026 22:20:48"',
                       "violations_waived"=>'4 5 6 7 8 9 10',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./spyglass-1/lint/lint_rtl/spyglass-1_waiver_file.awl"',
                       "waiverline"=>'2'
                      );

spyWaiversDataCount("totalWaivers"=>'2',
"totalWaiversApplied"=>'2',
"totalWaiversWithRegExp"=>'0',
"totalWaiversWithRuleSpecified"=>'2',
"totalWaiversWithIpSpecified"=>'0',
"totalWaiversWithFileLine"=>'0',
                         );

spyProhibitWaiverRules(                         );

spySetWaivedViolationNumberHash("");

1;
