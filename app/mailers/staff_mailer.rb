class StaffMailer < ActionMailer::Base

  def staffrequest(body, from, to, group, subject, event, person)
    @event = event
    @person = person
    if subject == nil || subject.length == 0
      @subject    = 'Vahvistus työvoimaan ilmoittautumisesta'
    else
      @subject    = subject
    end
    if body == nil || body.length == 0
      body = 'Olet ilmoittautunut työvoimaksi ryhmään ' + group + '.'
    end
    @body = body
    mail( :from => from, :to => to, :subject => @subject )
  end

  def staffconfirm(body, from, to, group, subject, person)
    if subject == nil || subject.length == 0
      @subject    = 'Vahvistus työvoimaan hyväksymisestä'
    else
      @subject    = subject
    end
    if body == nil || body.length == 0
      body = 'Sinut on hyväksytty työvoimaksi ryhmään ' + group + '.'
    end
    @body = body
    @person = person
    @group = group
    mail( :from => from, :to => to, :subject => @subject )
  end

end
