import construction.Constructible;
import constructions;
import resources;

class ConstructionConstructible : Constructible {
	Construction@ cons;
	bool isTimed = false;
	double timeProgress = 0;

	ConstructionConstructible(Object& obj, const ConstructionType@ type, const Targets@ targs) {
		@cons = Construction(type);
		cons.targets = targs;
		@cons.obj = obj;

		buildCost = type.getBuildCost(obj, targs);
		maintainCost = type.getMaintainCost(obj, targs);
		totalLabor = type.getLaborCost(obj, targs);
		if(totalLabor == 0) {
			totalLabor = max(type.getTimeCost(obj, targs), 1.0);
			isTimed = true;
		}
	}

	bool repeat(Object& obj) {
		if(!Constructible::repeat(obj))
			return false;
		if(!cons.type.canBuild(obj, cons.targets))
			return false;
		buildCost = cons.type.getBuildCost(obj, cons.targets);
		maintainCost = cons.type.getMaintainCost(obj, cons.targets);
		totalLabor = cons.type.getLaborCost(obj, cons.targets);
		if(totalLabor == 0) {
			totalLabor = max(cons.type.getTimeCost(obj, cons.targets), 1.0);
			isTimed = true;
		}
		else {
			isTimed = false;
		}
		timeProgress = 0;
		return true;
	}

	bool pay(Object& obj) {
		if(buildCost != 0) {
			if(cons.type.alwaysBorrowable && !repeated) {
				budgetCycle = obj.owner.lowerBudget(buildCost);
			}
			else {
				budgetCycle = obj.owner.consumeBudget(buildCost, borrow=!repeated);
				if(budgetCycle == -1)
					return false;
			}
		}
		paid = true;
		cons.start(this);
		return true;
	}

	ConstructionConstructible(SaveFile& file) {
		Constructible::load(file);
		@cons = Construction();
		file >> cons;
		if(file >= SV_0110) {
			file >> isTimed;
			file >> timeProgress;
		}
	}

	void save(SaveFile& file) {
		Constructible::save(file);
		file << cons;
		file << isTimed;
		file << timeProgress;
	}

	ConstructibleType get_type() {
		return CT_Construction;
	}

	string get_name() {
		return cons.type.name;
	}

	bool tick(Object& obj, double time) {
		if(isTimed) {
			timeProgress += time;
			curLabor = timeProgress;
		}
		cons.tick(this, time);
		return true;
	}

	bool isUsingLabor(Object& obj) {
		return !isTimed;
	}

	void cancel(Object& obj) override {
		Constructible::cancel(obj);
		cons.cancel(this);
	}

	void complete(Object& obj) {
		cons.finish(this);
	}

	void write(Message& msg) {
		Constructible::write(msg);
		msg << cons.type.id;
		msg << isTimed;
	}
};
