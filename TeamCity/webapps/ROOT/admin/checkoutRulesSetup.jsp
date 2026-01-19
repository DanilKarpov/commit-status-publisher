<%@ page import="jetbrains.buildServer.controllers.admin.projects.util.CheckoutRulesValidator" %>
<%@include file="/include-internal.jsp"%>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<jsp:useBean id="checkoutPathBean" type="jetbrains.buildServer.controllers.admin.projects.CheckoutRulesController.CheckoutPathBean" scope="request"/>
<jsp:useBean id="vcsRoot" type="jetbrains.buildServer.vcs.SVcsRoot" scope="request"/>
<c:set var="rootDirName" value="<${vcsRoot.name} Root>"/>
<c:set var="trunkAndBranchesReason" value="<%=CheckoutRulesValidator.CheckoutRulesRequiredReason.TRUNK_AND_BRANCHES_LAYOUT%>"/>
<c:set var="conflictingMappedPathReason" value="<%=CheckoutRulesValidator.CheckoutRulesRequiredReason.CONFLICTING_MAPPED_PATH%>"/>
<c:set var="showMappedPath" value="${checkoutPathBean.checkoutRulesRequiredReason == conflictingMappedPathReason}"/>

<admin:editBuildTypePage selectedStep="vcsRoots">
  <jsp:attribute name="head_include">
    <script type="text/javascript">
      BS.CheckoutPathForm = OO.extend(BS.AbstractWebForm, {
        formElement: function() {
          return $('checkoutPathForm');
        },

        insertPath: function(file) {
          var res = file;
          if (res.indexOf('/') == 0) {
            res = res.substr(1);
          }
          if (res.indexOf('<bs:escapeForJs text="${rootDirName}"/>/') == 0) {
            res = res.substr('<bs:escapeForJs text="${rootDirName}"/>'.length + 1);
          }

          var pathVal = res;
          if (res.length == 0) {
            res = ".";
            pathVal = '.';
          }

          $j('#checkoutPathText').html(res);
          this.formElement().checkoutPath.value = pathVal;
        },

        submit: function() {
          var that = this;
          BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
            checkoutPath: function (elem) {
              $('errorCheckoutPath').innerHTML = elem.firstChild.nodeValue;
              that.highlightErrorField($('checkoutPath'));
            },

            mappedPath: function (elem) {
              $('errorMappedPath').innerHTML = elem.firstChild.nodeValue;
              that.highlightErrorField($('mappedPath'));
            },

            vcsRootId: function (elem) {
              alert(elem.firstChild.nodeValue);
            },

            onCompleteSave: function (form, responseXML, err) {
              BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

              if (!err) {
                BS.XMLResponse.processRedirect(responseXML);
              }
            }
          }));
          return false;
        }
      });
    </script>
    <style type="text/css">
      #checkoutPathForm {
        width: 90%;
      }

      table.runnerFormTable th {
        width: 23%;
      }

      #checkoutPathText, #mappedPathText {
      }

      p.attentionComment {
        border: none;
        background-color: var(--ring-content-background-color, #fff);
      }
    </style>
  </jsp:attribute>
  <jsp:attribute name="body_include">

  <form id="checkoutPathForm" action="<c:url value='/admin/checkoutRulesSetup.html'/>" onsubmit="return BS.CheckoutPathForm.submit()">
    <bs:unprocessedMessages/>

    <div class="section noMargin">
      <h2 class="noBorder">Update Checkout Rules</h2>
    </div>

    <c:choose>
      <c:when test="${checkoutPathBean.checkoutRulesRequiredReason == trunkAndBranchesReason}">
        <p class="attentionComment"><bs:buildStatusIcon type="red-sign" className="warningIcon"/><strong><c:out value="${vcsRoot.name}"/></strong> VCS root contains directories corresponding to different branches.
          Please specify which directory in <strong><c:out value="${vcsRoot.name}"/></strong> VCS root should be checked out.</p>
      </c:when>
      <c:when test="${checkoutPathBean.checkoutRulesRequiredReason == conflictingMappedPathReason}">
        <p class="attentionComment"><bs:buildStatusIcon type="red-sign" className="warningIcon"/><strong><c:out value="${vcsRoot.name}"/></strong> VCS root is checked out into the same location as another VCS root in this build configuration.
        To avoid this intersection you can checkout <strong><c:out value="${vcsRoot.name}"/></strong> content in a subdirectory.</p>
      </c:when>
    </c:choose>

    <table class="runnerFormTable">
      <tr>
        <th class="noBorder">Directory to checkout:</th>
        <td class="noBorder">
          <div id="vcsTree"></div>
        </td>
      </tr>
      <c:if test="${showMappedPath}">
        <tr>
          <th class="noBorder">
            Subdirectory where to checkout:<l:star/>
          </th>
          <td class="noBorder">
            <forms:textField name="mappedPath" className="longField" value="." onkeyup="$('mappedPathText').textContent = this.value"/>
            <span id="errorMappedPath" class="error"></span>
          </td>
        </tr>
      </c:if>
      <tr>
        <td class="noBorder">
          Resulting checkout rule:
        </td>
        <td class="noBorder">
          +:<span id="checkoutPathText">.</span> => <span id="mappedPathText">.</span>
        </td>
      </tr>
    </table>

    <div class="saveButtonsBlock">
      <forms:submit label="Update Checkout Rules"/>
      <forms:cancel cameFromSupport="${buildForm.cameFromSupport}"/>
      <forms:saving/>
    </div>

    <script type="text/javascript">
      <c:if test="${not showMappedPath}">
      $j(document).on("bs.treeLoaded", function() {
        $j('#vcsTree .closed:first span.a').each( function() { this.click() } );
      });
      </c:if>

      BS.VCS.registerTree('vcsTree', 'vcsTree', '${buildForm.settingsId}', 'BS.CheckoutPathForm.insertPath', { dirsOnly: true, vcsRootId: '${vcsRoot.externalId}', rootDirName: '<bs:escapeForJs text="${rootDirName}"/>' } );
      BS.VCS.showTree('vcsTree');

    </script>

    <c:if test="${not showMappedPath}">
    <input type="hidden" name="mappedPath"  value="."/>
    </c:if>
    <input type="hidden" name="checkoutPath"  value="."/>
    <input type="hidden" name="id"  value="${buildForm.settingsId}"/>
    <input type="hidden" name="vcsRootId" value="${vcsRoot.externalId}"/>
  </form>
  </jsp:attribute>
</admin:editBuildTypePage>
