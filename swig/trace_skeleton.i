 /* trace_skeleton.i */
 %module trace_skeleton
 %{
 void trace(char* im, int w, int h);
 int pop_point();
 int len_polyline();
 %}
 
 void trace(char* im, int w, int h);
 int pop_point();
 int len_polyline();

%pythoncode %{
def from_list(arr,w,h):
	im = "".join(['\0' if x == 0 else '\1' for x in arr])
	trace(im,w,h)
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

def from_list2d(arr):
	if (len(arr) == 0):
		return []
	flatten = lambda l: [item for sublist in l for item in sublist]
	return from_list(flatten(arr),len(arr[0]),len(arr))

def from_numpy(arr):
	w = arr.shape[1]
	h = arr.shape[0]
	return from_list(list(arr.flatten()),w,h)
%}