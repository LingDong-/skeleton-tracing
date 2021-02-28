 /* trace_skeleton.i */
 %module trace_skeleton
 %{
 void trace(char* im, int w, int h, int csize, int maxIter);
 int pop_point();
 int len_polyline();
 %}

 void trace(char* im, int w, int h, int csize, int maxIter);
 int pop_point();
 int len_polyline();

%pythoncode %{
csizeDefault = 10
maxIterDefault = 999

def from_list(arr, w, h, csize=csizeDefault, maxIter=maxIterDefault):
	im = str(bytes(arr), 'ascii')
	trace(im, w, h, csize, maxIter)
	P = [];
	while (len_polyline() != -1):
		P.append([])
		n = len_polyline();
		for i in range(0,n):
			idx = pop_point()
			x = idx % w;
			y = idx //w;
			P[-1].append((x,y))
	return P

def from_list2d(arr, csize=csizeDefault, maxIter=maxIterDefault):
	if (len(arr) == 0):
		return []
	flatten = lambda l: [item for sublist in l for item in sublist]
	return from_list(flatten(arr), len(arr[0]), len(arr), csize, maxIter)

def from_numpy(arr, csize=csizeDefault, maxIter=maxIterDefault):
	w = arr.shape[1]
	h = arr.shape[0]
	arr[arr > 0] = 1
	return from_list(arr.flatten().tolist(), w, h, csize, maxIter)
%}
