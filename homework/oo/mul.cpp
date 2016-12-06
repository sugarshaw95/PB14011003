    #include<iostream>  
    using namespace std;  
 template<typename dst_type,typename src_type>
dst_type pointer_cast(src_type src)
{
    return *static_cast<dst_type*>(static_cast<void*>(&src));
};     
    class A  
    {  
    public:  
        int x;  
        A(int a){x=a;} 
                void disp()  
        {  
            cout<<"x="<<A::x<<endl;  
        }  
    };  
      
    class B:public A  
    {  
    public:  
        int y;  
        B(int a, int b):A(b){y=a;}
                void disp()  
        {  
            cout<<"x="<<B::x<<", y="<<y<<endl;  

        }   
    };  
      
    class C:public A  
    {  
    public:  
        int z;  
        C(int a, int b):A(b){z=a;}  
                void disp()  
        {  
 
            cout<<"x="<<C::x<<", z="<<z<<endl;  

        } 
    };  
      
    class D:public B, public C  
    {  
    public:  
        int m;  
        D(int a, int b, int c, int d, int e):B(a,b),C(c,d){m=e;}  
        void disp()  
        {  
            cout<<"x="<<B::x<<", y="<<y<<endl;  
            cout<<"x="<<C::x<<", z="<<z<<endl;  
            cout<<"m="<<m<<endl;  
        }  
    };  
      
    int main()  
    {  
        D d1(1,2,3,4,5);  
        d1.disp(); 
        void* p1 = pointer_cast<void*>(&A::disp);
        void* p2 = pointer_cast<void*>(&B::disp);
        void* p3 = pointer_cast<void*>(&C::disp);
        void* p4 = pointer_cast<void*>(&D::disp);
        void* p5 = pointer_cast<void*>(&d1.B::x);
        void* p6= pointer_cast<void*>(&d1.y);
                void* p7 = pointer_cast<void*>(&d1.C::x); 
        void* p8 = pointer_cast<void*>(&d1.z);
        void* p9 = pointer_cast<void*>(&d1.m);
 
                cout<<"各成员函数地址为:"<<endl;
        cout<<p1<<endl<<p2<<endl<<p3<<endl<<p4<<endl;
        cout<<"B::x,y,C::x,z,m地址依次为:"<<endl; 
        cout<<p5<<endl<<p6<<endl<<p7<<endl<<p8<<endl<<p9<<endl; 

        return 0;  
    }  
