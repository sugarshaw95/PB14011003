int a;
int main()
{
	int i;
	a=0;
	for(i=0;i<10;i++)
	{
		if(i%2==0)
			a++;
		if(i==9)
			break;
	}
	return 0;
}
