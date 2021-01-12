/*****************************************************************************
 *
 * SETS
 *
 *****************************************************************************/
{int} Depot_0 = ...;
{int} Depot_N1 = ...;

{int} Stations = ...;
{int} Stations_0 = Depot_0 union Stations;

{int} Customers = ...;
{int} Customers_0 = Depot_0 union Customers;

{int} StationsCustomers =  Stations union Customers;
{int} StationsCustomers_0 = Depot_0 union Stations union Customers; 
{int} StationsCustomers_N1 = Stations union Customers union Depot_N1;

{int} Total = Depot_0 union Stations union Customers union Depot_N1;

int VehiclesNumber = ...;
range Vehicles = 1..VehiclesNumber;

/*****************************************************************************
 *
 * PARAMETERS
 *
 *****************************************************************************/

//Travel time
int v = ...; // Average vehicle's velocity [km/h]
float Time[Total][Total]; // Cost or distance between i and j

// Distance
float   XCoord[Total] = ...;
float   YCoord[Total] = ...;
float d[Total][Total]; // Cost or distance between i and j

// Capacity
float C = ...;

// Battery
float Q = ...;

// Charging and discharging rate
float g = ...; // recharging rate
float h = ...; // charge consumption rate

// Demand
float q[Total] = ...;

// Time windows
float e[Total] = ...; // Lower Bound of the Time Window
float l[Total] = ...; // Upper Bound of the Time Window
float s[Total] = ...;

execute INITIALIZE {
	for(var i in Total) {
		for (var j in Total){
			if (i == j) {
				d[i][j] = 0;
				Time[i][j] = 0;
			} else {
			    d[i][j] = Math.floor(Math.sqrt(Math.pow(XCoord[i]-XCoord[j], 2) + Math.pow(YCoord[i]-YCoord[j], 2))*10)/10;
		        Time[i][j] = d[i][j]/v;
	       	}
	     }
     }
}

/*****************************************************************************
 *
 * Decision variables and objective function
 *
 *****************************************************************************/

dvar float+ t[Vehicles][Total]; // time arrival at vertex i
dvar float+ u[Vehicles][Total]; // remaining cargo at vertex i
dvar float+ y[Vehicles][Total]; // remaining battery at vertex i
dvar boolean x[Vehicles][StationsCustomers_0][StationsCustomers_N1]; // 1 if a vehicle drives directly from vertex i to vertex j
     
// Objective function [1]

minimize sum(k in Vehicles, i in StationsCustomers_0, j in StationsCustomers_N1 : i != j) (d[i][j]*x[k][i][j]);

/*****************************************************************************
 *
 * Constraints
 *
 *****************************************************************************/

subject to {

   	// Each customer is visited exactly once [2]
	forall (i in Customers)
		sum(k in Vehicles, j in StationsCustomers_N1 : i != j) x[k][i][j] == 1;
		
   	// Each stations is visited more than once [3]
	forall (i in Stations)
		sum(k in Vehicles, j in StationsCustomers_N1 : i != j) x[k][i][j] <= 1;

   	// After a vehicle arrives at a customer it has to leave for another destination [4]
   	forall(j in StationsCustomers)
     	sum(k in Vehicles, i in StationsCustomers_N1 : i != j) x[k][j][i] - sum(k in Vehicles, i in StationsCustomers_0 : i != j) x[k][i][j] == 0;
    
    // time feasibility for arcs leaving customers and depots [5]
    forall(k in Vehicles, i in Customers_0, j in StationsCustomers_N1 : i != j)
      t[k][i] + (Time[i][j] + s[i])*x[k][i][j] - l[0]*(1-x[k][i][j]) <= t[k][j];

    // time feasibility for arcs leaving recharging and depots [6]
    forall(k in Vehicles, i in Stations, j in StationsCustomers_N1 : i != j)
      t[k][i] + Time[i][j]*x[k][i][j] + g*(Q-y[k][i]) - (l[0]+(Q*g))*(1-x[k][i][j]) <= t[k][j];
      
    // Every vertex is visited within the time window [7]
    forall(k in Vehicles, j in Total)
      e[j] <= t[k][j] <= l[j];
      
    // demand fulfillment at all costumers [8],[9]
    forall(k in Vehicles, i in StationsCustomers_0, j in StationsCustomers_N1 : i != j)
     u[k][j] <= u[k][i] - q[i]*x[k][i][j] + C*(1-x[k][i][j]);    
	forall(k in Vehicles)     
     u[k][0] <= C;

	// battery constraints [10], [11]
    forall(k in Vehicles, i in Customers, j in StationsCustomers_N1 : i != j)
      y[k][j] <= y[k][i] - (h*d[i][j])*x[k][i][j] + Q*(1-x[k][i][j]);
      
    forall(k in Vehicles, i in Stations_0, j in StationsCustomers_N1 : i != j)
      y[k][j] <= Q - (h*d[i][j])*x[k][i][j];
	
};

execute DISPLAY {
    writeln("Solutions: ");
	for(var k in Vehicles)
		for(var i in StationsCustomers_0)
			for (var j in StationsCustomers_N1)
				if(x[k][i][j] == 1)
					writeln("vehicle ", k, " from ", i, " to ", j);
}
