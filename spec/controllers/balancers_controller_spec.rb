require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe BalancersController do
  login_user

  # This should return the minimal set of attributes required to create a valid
  # Balancer. As you add validations to Balancer, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {
        name: "blarg-role",
        primary: true,
    }
  end

  describe "GET index" do
    it "assigns all balancers as @balancers" do
      balancer = Balancer.create! valid_attributes
      get :index, {}
      assigns(:balancers).should eq([balancer])
    end
  end

  describe "GET show" do
    it "assigns the requested balancer as @balancer" do
      balancer = Balancer.create! valid_attributes
      get :show, {:id => balancer.to_param}
      assigns(:balancer).should eq(balancer)
    end
  end

  describe "GET new" do
    it "assigns a new balancer as @balancer" do
      get :new, {}
      assigns(:balancer).should be_a_new(Balancer)
    end
  end

  describe "GET edit" do
    it "assigns the requested balancer as @balancer" do
      balancer = Balancer.create! valid_attributes
      get :edit, {:id => balancer.to_param}
      assigns(:balancer).should eq(balancer)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Balancer" do
        expect {
          post :create, {:balancer => valid_attributes}
        }.to change(Balancer, :count).by(1)
      end

      it "assigns a newly created balancer as @balancer" do
        post :create, {:balancer => valid_attributes}
        assigns(:balancer).should be_a(Balancer)
        assigns(:balancer).should be_persisted
      end

      it "redirects to the created balancer" do
        post :create, {:balancer => valid_attributes}
        response.should redirect_to(Balancer.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved balancer as @balancer" do
        # Trigger the behavior that occurs when invalid params are submitted
        Balancer.any_instance.stub(:save).and_return(false)
        post :create, {:balancer => {}}
        assigns(:balancer).should be_a_new(Balancer)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Balancer.any_instance.stub(:save).and_return(false)
        post :create, {:balancer => {}}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested balancer" do
        balancer = Balancer.create! valid_attributes
        # Assuming there are no other balancers in the database, this
        # specifies that the Balancer created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Balancer.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => balancer.to_param, :balancer => {'these' => 'params'}}
      end

      it "assigns the requested balancer as @balancer" do
        balancer = Balancer.create! valid_attributes
        put :update, {:id => balancer.to_param, :balancer => valid_attributes}
        assigns(:balancer).should eq(balancer)
      end

      it "redirects to the balancer" do
        balancer = Balancer.create! valid_attributes
        put :update, {:id => balancer.to_param, :balancer => valid_attributes}
        response.should redirect_to(balancer)
      end
    end

    describe "with invalid params" do
      it "assigns the balancer as @balancer" do
        balancer = Balancer.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Balancer.any_instance.stub(:save).and_return(false)
        put :update, {:id => balancer.to_param, :balancer => {}}
        assigns(:balancer).should eq(balancer)
      end

      it "re-renders the 'edit' template" do
        balancer = Balancer.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Balancer.any_instance.stub(:save).and_return(false)
        put :update, {:id => balancer.to_param, :balancer => {}}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested balancer" do
      balancer = Balancer.create! valid_attributes
      expect {
        delete :destroy, {:id => balancer.to_param}
      }.to change(Balancer, :count).by(-1)
    end

    it "redirects to the balancers list" do
      balancer = Balancer.create! valid_attributes
      delete :destroy, {:id => balancer.to_param}
      response.should redirect_to(balancers_url)
    end
  end

end
