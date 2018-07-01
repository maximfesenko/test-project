global class FlightHanlder {

	webservice String parameter { get; set; }

	public FlightHanlder() {
		this.parameter = 'value';
	}

	webservice static String serviceName(){
		return '';
	}
}