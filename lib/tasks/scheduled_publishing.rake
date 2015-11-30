namespace :publishing do
  namespace :scheduled do
    desc "List editions scheduled for publication"
    task :list => :environment do
      previous = nil
      puts "%6s  %-25s  %s" % ["ID", "Scheduled date", "Title"]
      now = Time.zone.now
      Edition.scheduled.order("scheduled_publication asc").each do |edition|
        if previous && previous.scheduled_publication < now && edition.scheduled_publication >= now
          puts "----NOW----"
        end
        puts "%6s  %-25s  %s" % [edition.id, edition.scheduled_publication.to_s, edition.title]
        previous = edition
      end
    end

    desc "Queues missing jobs for any scheduled editions (including overdue ones)"
    task :queue_missing_jobs => :environment do
      queued_ids      = ScheduledPublishingWorker.queued_edition_ids
      missing_jobs    = Edition.scheduled.select { |edition| !queued_ids.include?(edition.id) }
      puts "#{Edition.scheduled.count} editions scheduled for publication, of which #{missing_jobs.size} do not have a job."

      puts "Queueing missing jobs..."
      missing_jobs.each do |edition|
        ScheduledPublishingWorker.queue(edition)
        puts "#{edition.id} queued"
      end
    end

    desc "Clears all jobs then requeues all scheduled editions (intended for use after a db restore)"
    task :requeue_all_jobs => :environment do
      ScheduledPublishingWorker.dequeue_all

      puts "Queueing #{Edition.scheduled.count} jobs"
      Edition.scheduled.each do |edition|
        ScheduledPublishingWorker.queue(edition)
        print "."
      end
      puts ""
    end
  end

  namespace :overdue do
    desc "List scheduled editions overdue for publication by more than one minute"
    task :list => :environment do
      puts "%6s  %-25s  %s" % ["ID", "Scheduled date", "Title"]
      Edition.due_for_publication(1.minute).each do |edition|
        puts "%6s  %-25s  %s" % [edition.id, edition.scheduled_publication.to_s, edition.title]
      end
    end

    desc "Publishes scheduled editions overdue for publication by more than one minute"
    task :publish => :environment do
      Edition.due_for_publication(1.minute).each do |edition|
        puts "Publishing overdue scheduled edition #{edition.id}"
        ScheduledPublishingWorker.new.perform(edition.id)
      end
    end
  end
end
