module first::costart {

    use aptos_framework::object::{Self};
    use std::string;
    use std::vector;
    use std::signer;
    use aptos_framework::randomness;
    use aptos_framework::event::{Self};

    struct Player has key,store{
        name: string::String,
        sender:address,
        guess: u8,
        score: u64,
    }

    struct PlayerList has key {
        players: vector<Player>,
    }

    #[event]
    struct SharePlayerListEvent has drop, store {
        playerlist: address
    }

    #[event]
    struct PlayerListAddressEvent has drop, store {
        playerlist: address
    }
    public fun create_player_list(): PlayerList {
        PlayerList { players: vector::empty() }
    }


    public fun create_player_list_share(creator: &signer): address {
        let creator_address = signer::address_of(creator);
        let obj = object::create_object(creator_address);
        let object_signer = object::generate_signer(&obj);
        let player_list = PlayerList { players: vector::empty() };
        move_to(&object_signer, player_list);

        let objaddress = object::address_from_constructor_ref(&obj);
        let event = SharePlayerListEvent{
          playerlist: objaddress
        };
        event::emit(event);

        objaddress
    }

    public fun hello(){

    }

    public fun add_player(player_list: &mut PlayerList, player: Player) {
        vector::push_back(&mut player_list.players, player);
    }

    public fun create_player(sender: &signer,name: string::String, score: u64): Player {
        Player { name,sender:signer::address_of(sender), guess:0,score }
    }

    public fun join_player(sender: &signer,player_list: &mut PlayerList, name: string::String, score: u64) {
        let player = Player { name,sender:signer::address_of(sender),guess:0, score };
        vector::push_back(&mut player_list.players, player);
    }

    fun init_module(sender: &signer) {

        let address = create_player_list_share(sender);
        let event = PlayerListAddressEvent{
            playerlist : address
        };
        event::emit(event);
    }

    fun guess():u8{
        randomness::u8_range(0, 100)
    }

    fun fight():bool{
        let ret = false;
        let fightComputer = guess();
        if(fightComputer > 50){
          ret = true;
        };
        ret
    }

    //let begin fighting
    fun fighting(player_list_address:address) acquires PlayerList {
        let player_list = borrow_global_mut<PlayerList>(player_list_address);
        let len = vector::length(&player_list.players);
        let i = 0;
        let glGuess = guess();
        while (i < len ){
            let player = vector::borrow_mut(&mut player_list.players, i);
            player.guess = randomness::u8_range(0, 100);

            //fighting
            //If team members win, points will be added
            if((player.guess as u8) > glGuess){
                player.score = player.score + 2;
            };

            i = i + 1;
        };

    }

    #[test_only]
    use std::string::utf8;
    #[test_only]
    use aptos_std::debug;


    #[test(aptos_framework = @aptos_framework)]
    fun randNumber(aptos_framework: &signer){
        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000003");
        let random_value = randomness::u8_range(0, 100);
        debug::print(&random_value);
        let guess =guess();
        debug::print(&guess);
        if(guess> random_value){
            debug::print(&utf8(b"you lose"));
        }
        else{
            debug::print(&utf8(b"you win"));
        };
    }

    #[test(user = @0x1,player1= @0x2,player2= @0x3)]
    public fun test(user: &signer,player1: &signer,player2: &signer){
        debug::print(&utf8(b"test"));

        let player_list = create_player_list();
        join_player(player1,&mut player_list, string::utf8(b"Alice"),10);
        join_player(player2,&mut player_list, string::utf8(b"Bob"),20);
        debug::print(&player_list);
        move_to(user, player_list);
    }

    #[test(creator = @0x42,player1= @0x2,player2= @0x3)]
    fun test_create_player_list(creator: &signer,player1: &signer,player2: &signer) acquires PlayerList {
        let player_list_address = create_player_list_share(creator);
        let player_list = borrow_global_mut<PlayerList>(player_list_address);

        let player = Player { name:string::utf8(b"Bob"),
            sender:signer::address_of(player1),
            guess:10, score:0 };
        vector::push_back(&mut player_list.players, player);

        let player2 = Player { name:string::utf8(b"alice"),
            sender:signer::address_of(player2),
            guess:20, score:0 };
        vector::push_back(&mut player_list.players, player2);

        let players_count = vector::length(&player_list.players);
        debug::print(&string::utf8(b"Player count: "));
        debug::print(&players_count);

        // room::create_room(creator,string::utf8(b"troom"));
    }
}