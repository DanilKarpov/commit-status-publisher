<%@ page import="java.util.UUID" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceConstants" %>

<%@ include file="/include-internal.jsp" %>
<%@ include file="_spaceConstants.jspf" %>
<%@ include file="_preSelectionSupport.jspf" %>

<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="afn" uri="/WEB-INF/functions/authz" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop" %>

<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="showMode" type="java.lang.String" scope="request"/>
<jsp:useBean id="availableParents" type="java.util.List" scope="request"/>

<jsp:include page="spaceApplicationCreator.jsp"/>

<c:set var="createSpaceApplicationId" value="<%=UUID.randomUUID().toString()%>"/>

<style type="text/css">
  .disable-click {
    pointer-events: none;
  }
</style>

<script type="text/javascript">
  BS.SpaceOnDemandCreator = OO.extend(BS.SpaceApplicationCreator, {

    startWaiting: function () {
      $j('#errorTimeout').hide();
      $j('#errorCreate').hide();
      $j('#connectButton').attr('disabled', 'disabled').addClass('disable-click');
      $j('#waiter, #waiterRing').show();
    },

    stopWaiting: function () {
      $j('#connectButton').removeAttr('disabled').removeClass('disable-click');
      $j('#waiter, #waiterRing').hide();
    },

    onTimeout: function () {
      $j('#errorTimeout').show();
    },

    onFailure: function(message, canTryAgain) {
      const text = (message) ? message : 'Space Application creation did not succeed, please try again';
      $j('#errorCreate').text(text);
      $j('#errorCreate').show();
      $j('#waiter').hide();
      if (canTryAgain) {
        $j('#connectButton').attr('disabled', 'disabled').addClass('disable-click');
      }
    },

    create: function () {
      let options;
      if (BS.SpacePreSelection.isOrganizationPreSelected()) {
        options = {organizationUrl: BS.SpacePreSelection.preSelectedOrganizationUrl};
      } else {
        options = null;
      }

      this.createApplication('${createSpaceApplicationId}',
        '${SpaceConstants.DEFAULT_TC_INSTANCE_NAME}',
        this.selectedParent(),
        this.onApplicationCreated,
        options);
    },

    onApplicationCreated(application) {
      console.log("application with client id ", application.clientId, " created, reloading...");
      BS.User.setProperty("lastSelectedCreateObjectOption", "space");
      const url = new URL(window.location.href);

      if (BS.SpacePreSelection.isOrganizationPreSelected()) {
        const cameFromUrl = url.searchParams.get('pageUrl');
        if (cameFromUrl) {
          window.location.href = cameFromUrl;
          return;
        }
        // in case we couldn't move to 'cameFromUrl', at least clean our params
        BS.SpacePreSelection.cleanUrl(url);
      }

      const oldParent = url.searchParams.get('projectId');
      const newParent = BS.SpaceOnDemandCreator.selectedParent();
      if (oldParent !== newParent) {
        url.searchParams.set('projectId', newParent);
        window.location.href = url.toString();
      } else {
        window.location.reload();
      }
    },

    selectedParent() {
      const parentIdSel = $('parentId');
      if (parentIdSel) {
        if (parentIdSel.options) {
          // parent project selector is shown
          const selected = parentIdSel.options[parentIdSel.selectedIndex];
          if (selected) {
            return selected.value;
          }
        } else {
          // parent project selector is hidden
          return parentIdSel.value;
        }
      }
      return '${project.externalId}';
    }
  });
</script>

<div>
  <table class="runnerFormTable">
    <tr>
      <th><label for="name">Parent project:<l:star/></label></th>
      <td>
        <bs:projectsFilter name="parentId" id="parentId"
                           projectBeans="${availableParents}"
                           selectedProjectExternalId="${project.externalId}"
                           disableRoot="${showMode == 'createBuildTypeMenu'}"/>
        <span class="error" id="errorParent"></span>
      </td>
    </tr>
    <tr>
      <th><label for="connectButton">Choose a repository:<l:star/></label></th>
      <td>
        <div>
          To show available repositories TeamCity requires a connection with JetBrains Space.
          <br/>
          <br/>
          <forms:button id="connectButton" onclick="BS.SpaceOnDemandCreator.create();" className="btn_primary submitButton">Connect</forms:button>
          <p id="waiter" style="display: none">
            <forms:saving id="waiterRing" style="float: none"/> Connecting to JetBrains Space...
          </p>
          <span class="error" id="errorTimeout" style="display: none">Connection could not be established.</span>
          <span class="error" id="errorCreate" style="display: none">Space Application creation did not succeed, please try again</span>
        </div>
      </td>
    </tr>
  </table>
</div>

