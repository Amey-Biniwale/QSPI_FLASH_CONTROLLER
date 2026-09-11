################################################################################
#This is an internally genertaed by spyglass to populate Waiver Info for Reports
#Note:Spyglass does not support any perl routine like "spyDecompileWaiverInfo"
#     The routine is purely for internal usage of spyglass
################################################################################


use SpyGlass;

spyClearWaiverHashInPerl(0);

spyComputeWaivedViolCount("totalWaivedViolationCount"=>'21',
                          "totalGeneratedCount"=>'0',
                          "totalReportCount"=>'0'
                         );

spyDecompileWaiverInfo("waive_cmd_id"=>'1',
                       "waiverCmd"=>'q%waive  -rule "STARC05-2.5.1.2" -comment "Created by ameybiniwale on 11-Sep-2026 22:22:50"%',
                       "-rule"=>'q%STARC05-2.5.1.2%',
                       "-comment"=>'"Created by ameybiniwale on 11-Sep-2026 22:22:50"',
                       "violations_waived"=>'22 23 24 25',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./spyglass-1/lint/lint_rtl_enhanced/spyglass-1_waiver_file.awl"',
                       "waiverline"=>'1'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'2',
                       "waiverCmd"=>'q%waive  -rule "TristatePort-ML" -comment "Created by ameybiniwale on 11-Sep-2026 22:22:55"%',
                       "-rule"=>'q%TristatePort-ML%',
                       "-comment"=>'"Created by ameybiniwale on 11-Sep-2026 22:22:55"',
                       "violations_waived"=>'18 19 20 21',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./spyglass-1/lint/lint_rtl_enhanced/spyglass-1_waiver_file.awl"',
                       "waiverline"=>'2'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'3',
                       "waiverCmd"=>'q%waive  -rule "W438" -comment "Created by ameybiniwale on 11-Sep-2026 22:23:02"%',
                       "-rule"=>'"W438"',
                       "-comment"=>'"Created by ameybiniwale on 11-Sep-2026 22:23:02"',
                       "violations_waived"=>'14 15 16 17',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./spyglass-1/lint/lint_rtl_enhanced/spyglass-1_waiver_file.awl"',
                       "waiverline"=>'3'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'4',
                       "waiverCmd"=>'q%waive  -rule "W444" -comment "Created by ameybiniwale on 11-Sep-2026 22:23:07"%',
                       "-rule"=>'"W444"',
                       "-comment"=>'"Created by ameybiniwale on 11-Sep-2026 22:23:07"',
                       "violations_waived"=>'10 11 12 13',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./spyglass-1/lint/lint_rtl_enhanced/spyglass-1_waiver_file.awl"',
                       "waiverline"=>'4'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'5',
                       "waiverCmd"=>'q%waive  -rule "W164a" -comment "Created by ameybiniwale on 11-Sep-2026 22:47:05"%',
                       "-rule"=>'"W164a"',
                       "-comment"=>'"Created by ameybiniwale on 11-Sep-2026 22:47:05"',
                       "violations_waived"=>'5 6 7 8 9',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./spyglass-1/lint/lint_rtl_enhanced/spyglass-1_waiver_file.awl"',
                       "waiverline"=>'5'
                      );

spyWaiversDataCount("totalWaivers"=>'5',
"totalWaiversApplied"=>'5',
"totalWaiversWithRegExp"=>'0',
"totalWaiversWithRuleSpecified"=>'5',
"totalWaiversWithIpSpecified"=>'0',
"totalWaiversWithFileLine"=>'0',
                         );

spyProhibitWaiverRules(                         );

spySetWaivedViolationNumberHash("");

1;
