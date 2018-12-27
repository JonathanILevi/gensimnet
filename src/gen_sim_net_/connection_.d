module gen_sim_net_.connection_;

import std.range.interfaces : InputRange;

interface Connection {
	InputRange!(const(ubyte)[]) msgs();
	void send(const(ubyte[]) msg);
	@property bool connected();
}
