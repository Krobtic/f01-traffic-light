STATES=["NS_GREEN","NS_YELLOW","EW_GREEN","EW_YELLOW"]

def output(state, night=False, flash=True):
    if night:
        return (0b010,0b010) if flash else (0,0)
    if state=="NS_GREEN": return (0b001,0b100)
    if state=="NS_YELLOW": return (0b010,0b100)
    if state=="EW_GREEN": return (0b100,0b001)
    if state=="EW_YELLOW": return (0b100,0b010)
    return (0b100,0b100)

def safe(a,b):
    return not ((a&1) and (b&1))

def run():
    assert len(STATES)==4
    assert (1 << 2) >= len(STATES)
    for s in STATES:
        a,b=output(s)
        assert safe(a,b)
    assert safe(*output("NS_GREEN",night=True,flash=True))
    assert safe(*output("NS_GREEN",night=True,flash=False))
    print("F01 reference model PASS")
    print("Normal FSM states:", STATES)
    print("Minimum binary state width:", 2)
    print("Night flashing implemented as a mode/output overlay, not a fifth state.")
    print("Safety property holds for all normal and night output conditions.")

if __name__=="__main__":
    run()
