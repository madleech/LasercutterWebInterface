var current_status = null;

var refresh_status = function() {
	$.post('/api/progress', function(response) {
		$('[data-id=current-job]').text(response.job);
		$('[data-id=job-progressbar]').val(Math.round(response.progress));
		$('[data-id=job-progress]').text(Math.round(response.progress)+'%');
		$('[data-id=status]').text(response.status);
		
		if (response.status != current_status) switch(response.status) {
			// has the job started?
			case 'cutting':
				play('start');
				break;
			// has the job finished?
			case 'finished':
				play('completed');
				break;
		}
		current_status = response.status;
	});
}

var update_temperature = function() {
	$.post('/api/temperature', function(response) {
		$('[data-id=temperature]').text(response.temperature.formatted);
	});
}

var play = function(id) {
	$('audio[data-sound-id='+id+']')[0].play();
}

$(function() {
	setInterval(refresh_status, 3000);
	setInterval(update_temperature, 30000);
	
	$('[data-id=home]').click(function() { $.post('/api/home'); });
	$('[data-id=abort]').click(function() { $.post('/api/abort'); });
	$('[data-id=reload-webcam').click(function() {
		img = $('img').slice(0, 1);
		img2 = img.clone();
		img.replaceWith(img2);
		console.log('replaced', img, 'with', img2);
	});
	
	refresh_status();
});
