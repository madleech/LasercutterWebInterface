var refresh_status = function() {
	$.post('/api/progress', function(response) {
		$('[data-id=current-job]').text(response.job);
		$('[data-id=job-progressbar]').css('width', Math.round(response.progress)+'px');
		$('[data-id=job-progress]').text(Math.round(response.progress)+'%');
		$('[data-id=status]').text(response.status);
	});
}

var update_webcam = function() {
	webcam = $('[data-id=webcam]');
	src = webcam.data('srcTemplate')
	if (!src) {
		src = webcam.attr('src');
		webcam.data('srcTemplate', src);
	}
	webcam.attr('src', src + '?' + Date.now());
}

var update_temperature = function() {
	$.post('/api/temperature', function(response) {
		$('[data-id=temperature]').text(response.temperature);
	});
}

$(function() {
	setInterval(refresh_status, 1500);
	setInterval(update_webcam, 10000);
	setInterval(update_temperature, 30000);
	
	refresh_status();
});
