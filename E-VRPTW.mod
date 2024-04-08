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

/*****************************************************************************
 *
 * PARAMETERS
 *
 *****************************************************************************/

//Travel time
float v = ...; // Average vehicle's velocity [km/h]
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

// Obejective coefficient
int M=1000; // implement that first objective is to minimize the number of vehicles
int objective1=0;
float objective2=0;

execute INITIALIZE {
	for(var i in Total) {
		for (var j in Total){
			if (i == j) {
				d[i][j] = 0;
				Time[i][j] = 0;
			} else {
			    d[i][j] = Math.sqrt(Math.pow(XCoord[i]-XCoord[j], 2) + Math.pow(YCoord[i]-YCoord[j], 2));
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

dvar float+ t[Total]; // time arrival at vertex i
dvar float+ u[Total]; // remaining cargo at vertex i
dvar float+ y[Total]; // remaining battery at vertex i
dvar boolean x[StationsCustomers_0][StationsCustomers_N1]; // 1 if a vehicle drives directly from vertex i to vertex j
     
// first objective is to minimize the number of vehicles and Objective function [1]

minimize sum(i in StationsCustomers_0, j in StationsCustomers_N1 : i != j) (d[i][j]*x[i][j]) + sum(j in StationsCustomers_N1) x[0][j]*M;

/*****************************************************************************
 *
 * Constraints
 *
 *****************************************************************************/

subject to {

   	// Each customer is visited exactly once [2]
	forall (i in Customers)
		sum(j in StationsCustomers_N1 : i != j) x[i][j] == 1;
		
   	// Each dummy stations is visited at most once [3]
	forall (i in Stations)
		sum(j in StationsCustomers_N1 : i != j) x[i][j] <= 1;

   	// After a vehicle arrives at a customer it has to leave for another destination [4]
   	forall(j in StationsCustomers)
     	sum(i in StationsCustomers_N1 : i != j) x[j][i] - sum(i in StationsCustomers_0 : i != j) x[i][j] == 0;
    
    // time feasibility for arcs leaving customers and depots [5]
    forall(i in Customers_0, j in StationsCustomers_N1 : i != j)
      t[i] + (Time[i][j] + s[i])*x[i][j] - l[0]*(1-x[i][j]) <= t[j];

    // time feasibility for arcs leaving recharging and depots [6]
    forall(i in Stations, j in StationsCustomers_N1 : i != j)
      t[i] + Time[i][j]*x[i][j] + g*(Q-y[i]) - (l[0]+(Q*g))*(1-x[i][j]) <= t[j];
      
    // Every vertex is visited within the time window [7]
    forall(j in Total)
      e[j] <= t[j] <= l[j];
      
    // demand fulfillment at all costumers [8],[9]
    forall(i in StationsCustomers_0, j in StationsCustomers_N1 : i != j)
     u[j] <= u[i] - q[i]*x[i][j] + C*(1-x[i][j]);    
     u[0] <= C;

	// battery constraints [10], [11]
    forall(i in Customers, j in StationsCustomers_N1 : i != j)
      y[j] <= y[i] - (h*d[i][j])*x[i][j] + Q*(1-x[i][j]);
      
    forall(i in Stations_0, j in StationsCustomers_N1 : i != j)
      y[j] <= Q - (h*d[i][j])*x[i][j];
	
};

execute DISPLAY {
    for (var j in StationsCustomers_N1) objective1 = objective1 + x[0][j];
    for (var i in StationsCustomers_0) {
        for (var j in StationsCustomers_N1) {
            objective2 = objective2 + d[i][j]*x[i][j]
        }
    }     
    writeln("Vehicle number(m): ", objective1);
    writeln("Traveled distance(f): ", objective2);
    writeln("Solutions: ");
    for(var i in StationsCustomers_0) {
        for (var j in StationsCustomers_N1) {
            if(x[i][j] == 1) {
                writeln("Travel from ", i, " to ", j);					
            }
        }
    }
}