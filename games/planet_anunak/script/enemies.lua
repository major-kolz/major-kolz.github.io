dinosaur1 = battle {
	nam = "Динозавр",
	hp = 13;
	dices = {
		{ m_jaw, m_claws, m_claws, m_nothing, m_flight, m_nothing };
		{ m_jaw, m_claws, m_claws, m_nothing, m_flight, m_nothing };
	};
};

dinosaur2 = battle {
	nam = "Динозавр",
	hp = 10;
	dices = {
		{ m_claws, m_claws, m_claws, m_nothing, m_flight, m_jaw,  };
		{ m_claws, m_claws, m_claws, m_nothing, m_flight, m_jaw,  };
	};
};

dinosaur3 = battle {
	nam = "Птеродактиль",
	hp = 8;
	dices = {
		{ m_jaw, m_claws, m_claws, m_flight, m_nothing, m_flight };
		{ m_jaw, m_claws, m_claws, m_flight, m_nothing, m_flight };
	};
};

dinosaur4 = battle {
	nam = "Трицератопс",
	hp = 10;
	won = 'p343_344';
	loose = 'p341';
	dices = {
		{ m_claws, m_claws, m_ram, m_ram, m_nothing, m_nothing };
		{ m_claws, m_claws, m_ram, m_ram, m_nothing, m_nothing };
		{ m_claws, m_claws, m_ram, m_ram, m_nothing, m_nothing };
	};
};

dinosaur5 = battle {
	nam = "Тираннозавр",
	hp = 10;
	dices = {
		{ m_jaw, m_jaw, m_jaw, m_ram, m_nothing, m_nothing };
		{ m_jaw, m_jaw, m_jaw, m_ram, m_nothing, m_nothing };
		{ m_jaw, m_jaw, m_jaw, m_ram, m_nothing, m_nothing };
		{ m_jaw, m_jaw, m_jaw, m_ram, m_nothing, m_nothing };
	};
};

dinosaur6 = battle {
	nam = "Динозавр",
	hp = 10;
	dices = {
		{ m_ram, m_claws, m_nothing, m_nothing, m_nothing, m_flight };
		{ m_ram, m_claws, m_nothing, m_nothing, m_nothing, m_flight };
	};
};

dinosaur7 = battle {
	nam = "Динозавр",
	hp = 10;
	dices = {
		{ m_claws, m_claws, m_claws, m_nothing, m_nothing, m_flight };
		{ m_claws, m_claws, m_claws, m_nothing, m_nothing, m_flight };
		{ m_claws, m_claws, m_claws, m_nothing, m_nothing, m_flight };
		{ m_claws, m_claws, m_claws, m_nothing, m_nothing, m_flight };
	};
};

dinosaur8 = battle {
	nam = "Динозавр",
	hp = 13;
	dices = {
		{ m_ram, m_ram, m_ram, m_nothing, m_nothing, m_flight };
		{ m_ram, m_ram, m_ram, m_nothing, m_nothing, m_flight };
		{ m_ram, m_ram, m_ram, m_nothing, m_nothing, m_flight };
		{ m_ram, m_ram, m_ram, m_nothing, m_nothing, m_flight };
	};
};

humans1 = battle {
	nam = "Враг 1",
   hp = 8;
	dices = {
		{ m_shot, m_shot, m_nothing, m_shot, m_nothing, m_flight },
		{ m_shot, m_shot, m_nothing, m_shot, m_nothing, m_flight },
		{ m_shot, m_shot, m_nothing, m_shot, m_nothing, m_flight },
	}
}

humans2 = battle {
	nam = "Враг 2",
   hp = 9;
	dices = {
		{ m_ram, m_shot, m_nothing, m_shot, m_nothing, m_flight },
		{ m_ram, m_shot, m_nothing, m_shot, m_nothing, m_flight },
		{ m_ram, m_shot, m_nothing, m_shot, m_nothing, m_flight },
		{ m_ram, m_shot, m_nothing, m_shot, m_nothing, m_flight },
	}
}

anaconda = battle {
	nam = "Анаконда",
	hp = 7;
	dices = {
		{ m_jaw, m_jaw, m_ram, m_ram, m_ram, m_nothing },
		{ m_jaw, m_jaw, m_ram, m_ram, m_ram, m_nothing },
		{ m_jaw, m_jaw, m_ram, m_ram, m_ram, m_nothing },
		{ m_jaw, m_jaw, m_ram, m_ram, m_ram, m_nothing },
	};
}

python = battle {
	nam = "Питон",
	hp = 7;
	dices = {
		{ m_jaw, m_jaw, m_ram, m_nothing, m_flight, m_jaw },
		{ m_jaw, m_jaw, m_ram, m_nothing, m_flight, m_jaw },
		{ m_jaw, m_jaw, m_ram, m_nothing, m_flight, m_jaw },
		{ m_jaw, m_jaw, m_ram, m_nothing, m_flight, m_jaw },
	};
}

cyborg = battle {
	nam = "Киборг",
	hp = 7,
	dices = {
		{ m_shot, m_shot, m_shot, m_nothing, m_shot, m_shot },
		{ m_shot, m_shot, m_shot, m_nothing, m_shot, m_shot },
		{ m_shot, m_shot, m_shot, m_nothing, m_shot, m_shot },
	};
}

monster1 = battle {
	nam = "Монстр 1",
	hp = 5,
	dices = {
		{ m_jaw, m_jaw, m_flight, m_nothing, m_flight, m_jaw },
		{ m_jaw, m_jaw, m_flight, m_nothing, m_flight, m_jaw },
		{ m_jaw, m_jaw, m_flight, m_nothing, m_flight, m_jaw },
	}
}

monster2 = battle {
	nam = "Монстр",
	hp = 8,
	won = 'monster2_win';
	loose = 'p264';
	dices = {
		{ m_ram, m_jaw, m_claws, m_nothing, m_flight, m_flight },
		{ m_ram, m_jaw, m_claws, m_nothing, m_flight, m_flight },
		{ m_ram, m_jaw, m_claws, m_nothing, m_flight, m_flight },
	}
}

monster3 = battle {
	nam = "Монстр 3",
	hp = 5,
	dices = {
		{ m_jaw, m_claws, m_claws, m_claws, m_flight, m_flight },
		{ m_jaw, m_claws, m_claws, m_claws, m_flight, m_flight },
	}
}

mosquitoes = battle {
	nam = "Москиты",
	hp = 13,
	dices = {
		{ m_ram, m_ram, m_ram, m_ram, m_ram, m_nothing },
		{ m_ram, m_ram, m_ram, m_ram, m_ram, m_nothing },
		{ m_ram, m_ram, m_ram, m_ram, m_ram, m_nothing },
		{ m_ram, m_ram, m_ram, m_ram, m_ram, m_nothing },
	}
}

spider = battle {
	nam = "Паук",
	hp = 4,
	dices = {
		{ m_claws, m_ram, m_nothing, m_nothing, m_flight, m_flight },
		{ m_claws, m_ram, m_nothing, m_nothing, m_flight, m_flight },
	}
}

scorpion = battle {
	nam = "Скорпион",
	hp = 5,
	dices = {
		{ m_ram, m_claws, m_claws, m_flight, m_flight, m_nothing },
		{ m_ram, m_claws, m_claws, m_flight, m_flight, m_nothing },
	}
}
