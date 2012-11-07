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

describe RecordsController do
  login_user

  # This should return the minimal set of attributes required to create a valid
  # Record. As you add validations to Record, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {
        type: "CNAME",
        ttl: "300",
        name: "app0.blarg.env.inqlabs.com",
        values: ["blarg.ec2.amazon.com"]
    }
  end

  describe "GET index" do
    it "assigns all records as @records" do
      record = Record.create! valid_attributes
      get :index, {}
      assigns(:records).should eq([record])
    end
  end

  describe "GET show" do
    it "assigns the requested record as @record" do
      record = Record.create! valid_attributes
      get :show, {:id => record.to_param}
      assigns(:record).should eq(record)
    end
  end

  describe "GET new" do
    it "assigns a new record as @record" do
      get :new, {}
      assigns(:record).should be_a_new(Record)
    end
  end

  describe "GET edit" do
    it "assigns the requested record as @record" do
      record = Record.create! valid_attributes
      get :edit, {:id => record.to_param}
      assigns(:record).should eq(record)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Record" do
        expect {
          post :create, {:record => valid_attributes}
        }.to change(Record, :count).by(1)
      end

      it "assigns a newly created record as @record" do
        post :create, {:record => valid_attributes}
        assigns(:record).should be_a(Record)
        assigns(:record).should be_persisted
      end

      it "redirects to the created record" do
        post :create, {:record => valid_attributes}
        response.should redirect_to(Record.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved record as @record" do
        # Trigger the behavior that occurs when invalid params are submitted
        Record.any_instance.stub(:save).and_return(false)
        post :create, {:record => {}}
        assigns(:record).should be_a_new(Record)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Record.any_instance.stub(:save).and_return(false)
        post :create, {:record => {}}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested record" do
        record = Record.create! valid_attributes
        # Assuming there are no other records in the database, this
        # specifies that the Record created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Record.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => record.to_param, :record => {'these' => 'params'}}
      end

      it "assigns the requested record as @record" do
        record = Record.create! valid_attributes
        put :update, {:id => record.to_param, :record => valid_attributes}
        assigns(:record).should eq(record)
      end

      it "redirects to the record" do
        record = Record.create! valid_attributes
        put :update, {:id => record.to_param, :record => valid_attributes}
        response.should redirect_to(record)
      end
    end

    describe "with invalid params" do
      it "assigns the record as @record" do
        record = Record.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Record.any_instance.stub(:save).and_return(false)
        put :update, {:id => record.to_param, :record => {}}
        assigns(:record).should eq(record)
      end

      it "re-renders the 'edit' template" do
        record = Record.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Record.any_instance.stub(:save).and_return(false)
        put :update, {:id => record.to_param, :record => {}}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested record" do
      record = Record.create! valid_attributes
      expect {
        delete :destroy, {:id => record.to_param}
      }.to change(Record, :count).by(-1)
    end

    it "redirects to the records list" do
      record = Record.create! valid_attributes
      delete :destroy, {:id => record.to_param}
      response.should redirect_to(records_url)
    end
  end

end
