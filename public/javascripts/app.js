var refresh_status = function() {
	$.post('/api/progress', function(response) {
		$('[data-id=current-job]').text(response.job);
		$('[data-id=job-progressbar]').css('width', Math.round(response.progress)+'px');
		$('[data-id=job-progress]').text(Math.round(response.progress)+'%');
		$('[data-id=status]').text(response.status);
	});
}

$(function() {
	setInterval(refresh_status, 1000);
});
