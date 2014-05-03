class GmController < Application
  before_filter :authorize, :except => [:index, :new, :create]
#  before_filter :authorize, :except => [:login]

  def index
    new
    render :action => 'new'
  end

  def new
    @person = Person.new
    @genre = nil
    @genres = AttributeValue.all(:conditions => "attribute_id in (select id from attributes where name='Genre') and visible = true",
                                :order => "value")
    @genres.each { |genre|
      if genre.defaultvalue
        @genre = genre
      end
    }

    begin
      render(:layout => "layouts/" + @event.name.to_s + "_staff" )
    rescue Exception
      render
    end
  end

  def create
    gmgroup = Persongroup.first(:conditions => ["name='GM' and event_id=?", @event.id])
    @person = Person.find_by_primary_email(params[:person][:primary_email])
    if @person != nil
      if @person.firstname != params[:person][:firstname] && @person.lastname != params[:person][:lastname]
        flash[:notice] = 'Tällä sähköpostiosoitteella on jo henkilö kannassa!'
        redirect_to :action => 'new'
        return
      end
      @person.nickname = params[:person][:nickname]
      @person.primary_phone = params[:person][:primary_phone]
    else
      @person = Person.create(params[:person])
    end
    gmgroup.add( @person, Statusname.find_by_name( 'Toive' ) )

    if params[:shirt]
      tshirt = params[:shirt][:value]
      ts = Attribute.first(:conditions => "name='Staff-paita'")
      ts.add( @event, @person, tshirt, params[:shirttext] )
    end

    num = 5
    if params[:game1][:name].length == 0
      flash[:notice] = 'Pitää ilmoittaa ainakin yksi peli!'
      redirect_to :action => 'new'
      return
    elsif params[:game2][:name].length == 0
      num = 1
    elsif params[:game3][:name].length == 0
      num = 2
    elsif params[:game4][:name].length == 0
      num = 3
    elsif params[:game5][:name].length == 0
      num = 4
    end
    @games = []
    for i in 1..num 
      gamesym = ("game" + i.to_s).to_sym
      game = Program.new
      game.name = params[gamesym][:name]
      game.attendance = params[gamesym][:attendance]
      game.description = params[gamesym][:description]
      game.publicnotes = params[gamesym][:publicnotes]
      game.event = @event
      game.privatenotes = "Ajankohta: " + params[gamesym][:preftime] + ", Kesto: " + params[gamesym][:duration] + ", " + params[gamesym][:privatenotes]
      game.status = -2
      game.save
      @games << game

      group = Programgroup.find(12)
      game.programgroups << group
      group.save

      genre = params[gamesym][:value]
      g = Attribute.first(:conditions => "name='Genre'")
      att = ProgramsEventsAttribute.first(:conditions => ["program_id=? and event_id=? and attribute_id=?", game.id, @event.id, g.id])
      if att == nil
        att = ProgramsEventsAttribute.new
      end
      att.program = game
      att.event = @event
      att.attribute = g
      att[:value] = genre
      att.save
      @event.save
      g.save
      game.save

      type = Attribute.first(:conditions => "name='Pelin tyyppi'")
      if params[gamesym][:beginner]
	att = ProgramsEventsAttribute.new
	att.program = game
	att.event = @event
	att.attribute = type
	att.value = 'Aloittelijaystävällinen'
	att.save
	@event.save
	type.save
	game.save
      end
      if params[gamesym][:worldknowledge]
	att = ProgramsEventsAttribute.new
	att.program = game
	att.event = @event
	att.attribute = type
	att.value = 'Pelimaailman tuntemus'
	att.save
	@event.save
	type.save
	game.save
      end
      if params[gamesym][:rulesknowledge]
	att = ProgramsEventsAttribute.new
	att.program = game
	att.event = @event
	att.attribute = type
	att.value = 'Pelisääntöjen tuntemus'
	att.save
	@event.save
	type.save
	game.save
      end
      if params[gamesym][:adult]
	att = ProgramsEventsAttribute.new
	att.program = game
	att.event = @event
	att.attribute = type
	att.value = 'Ei sovellu lapsille'
	att.save
	@event.save
	type.save
	game.save
      end

      organizer = ProgramsOrganizer.new
      organizer.person = @person
      organizer.program = game
      organizer.orgtype = 1
      organizer.save
      game.save
    end
    @person.save
    realbody = @event.registration
    realbody = realbody + "\n\n"
    realbody = realbody + @person.details( @event )
    for game in @games
      realbody = realbody + "\n"
      realbody = realbody + game.name + "\n"
      realbody = realbody + game.description + "\n"
      realbody = realbody + game.attendance + "\n"
      realbody = realbody + game.publicnotes + "\n"
    end
    StaffMailer.confirm(realbody, "gm-info@ropecon.fi", @person.primary_email, nil, @event.name + " - ilmoittautuminen").deliver
  end

  def list
    @gms = Person.find_by_sql("select distinct people.* from people, persongroups, people_persongroups, events where people.id=people_persongroups.person_id and persongroups.id=people_persongroups.persongroup_id and persongroups.event_id=events.id and events.ispublic=true and persongroups.name='GM'")
    @duplicates = {}
    for gm in @gms
      duplicate = Person.find_by_sql(["select distinct people.* from people where firstname = ? and lastname = ? and id != ?", gm.firstname, gm.lastname, gm.id])
      if duplicate != nil
        @duplicates[gm.id] = duplicate
      end
    end
  end

  def confirm
    program = Program.find(params[:id])
    program.status = -1
    program.save
    for organizer in program.programs_organizers.person.people_persongroups
      if organizer.event.id == @event.id && organizer.name == 'GM'
        organizer.status = -1
        organizer.save
      end
    end
    redirect_to :action => 'list'
  end

  def show
    @staff = Person.find(params[:id])
  end

  def destroy
    Program.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

end
