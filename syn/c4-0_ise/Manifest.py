target = "xilinx"
action = "synthesis"

syn_device = "xc6slx45"
syn_grade = "-3"
syn_package = "fgg484"
syn_top = "bridge"
syn_project = "bridge.xise"
syn_tool = "ise"

modules = {
        "local" : [ "../../top/c4-0" ],
}
