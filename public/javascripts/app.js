var refresh_status = function() {
	$.post('/api/progress', function(response) {
		$('[data-id=current-job]').text(response.job);
		$('[data-id=job-progressbar]').css('width', Math.round(response.progress)+'px');
		$('[data-id=job-progress]').text(Math.round(response.progress)+'%');
		$('[data-id=status]').text(response.status);
	});
}


var update_temperature = function() {
	$.post('/api/temperature', function(response) {
		$('[data-id=temperature]').text(response.temperature);
	});
}

$(function() {
	setInterval(refresh_status, 1500);
	setInterval(update_temperature, 30000);
	
	refresh_status();
});
