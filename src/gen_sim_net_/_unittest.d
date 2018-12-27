module gen_sim_net_._unittest;

import gen_sim_net_.listener_;
import gen_sim_net_.connect_to_;
import vibe.core.core : sleep;
import core.time;

unittest {
	auto listener = new Listener(1111);
	
	sleep(100.msecs);
	
	auto to = connectTo("127.0.0.1",1111);
	assert(to.connected);
	
	sleep(10.msecs);
	
	auto news = listener.getNewConnections();
	assert(news.length>0);
	auto from = news[0];
	assert(from.connected);
	
	sleep(10.msecs);
	
	to.send([1,2,4]);
	sleep(100.msecs);
	foreach (msg; from.msgs) {
		import std.stdio;
		msg.writeln;
		assert(msg==[1,2,4]);
		break;
	}
	
	from.send([2,9,54]);
	sleep(100.msecs);
	foreach (msg; to.msgs) {
		assert(msg==[2,9,54]);
		break;
	}
}

