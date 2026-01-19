<%@include file="/include-internal.jsp"%>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="cameFromSupport" type="jetbrains.buildServer.web.util.CameFromSupport" scope="request"/>
<bs:page disableScrollingRestore="true">
  <jsp:attribute name="page_title">Create Template</jsp:attribute>

  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/admin/adminMain.css
      /css/admin/buildTypeForm.css
    </bs:linkCSS>
    <bs:linkScript>
    </bs:linkScript>
    <script type="text/javascript">
      <bs:trimWhitespace>
        <admin:projectPathJS startProject="${project}" startAdministration="${true}"/>

        BS.Navigation.items.push({
          title: "Create Template",
          url: '${pageUrl}',
          selected: true
        });

      $j(document).ready(function() {
        $('templateName').focus();
      });
      </bs:trimWhitespace>

      ReactUI.setActivePageId('projects');
    </script>
  </jsp:attribute>

  <jsp:attribute name="body_include">
    <div id="container" class="clearfix" style="width:70%;">
      <bs:unprocessedMessages/>

      <c:url value='/admin/createTemplate.html' var="actionUrl"/>
      <form id="createTemplateForm" action="${actionUrl}" onsubmit="return BS.CreateTemplateForm.submit()">
        <table class="runnerFormTable">
          <c:set var="subProjects" value="${project.projects}"/>
          <c:if test="${fn:length(subProjects) >= 1}">
            <tr>
              <th>
                <label for="parentProjectId"><strong>Parent project:</strong></label>
              </th>
              <td>
                <select hidden name="parentProjectId" id="parentProjectId">
                  <option value="${project.externalId}" selected></option>
                  <c:forEach items="${subProjects}" var="p"
                    ><option value="${p.externalId}"></option
                    ></c:forEach>
                </select>
                <div id="parentProjectIdSelect"></div>
                <script>
                  {
                    const select = document.getElementById('parentProjectId');
                    ReactUI.renderConnected(document.getElementById('parentProjectIdSelect'), ReactUI.ProjectBuildTypeSelect, {
                      expandAll: true,
                      projectsSelectable: true,
                      buildTypesSelectable: false,
                      includedProjects: [...select.options].map(option => option.value),
                      selected: {nodeType: 'project', id: '${project.externalId}'},
                      onSelect(item) {
                        select.value = item.id
                      }
                    })
                  }
                </script>
                <span class="error" id="error_parentProject"></span>
              </td>
            </tr>
          </c:if>

          <tr>
            <th>
              <label for="templateName"><strong>Name:<l:star/></strong></label>
            </th>
            <td>
              <forms:textField name="templateName" maxlength="80" className="longField"/>
              <span class="error" id="error_templateName"></span>
              <span class="error" id="error_createTemplateFailed"></span>
            </td>
          </tr>
          <tr>
            <th>
              <label for="templateExternalId"><strong>Template ID:<l:star/></strong><bs:help file="Entity+IDs"/></label>
            </th>
            <td>
              <forms:textField name="templateExternalId" maxlength="256" className="longField"/>
              <span class="smallNote">This ID is used in URLs, REST API, HTTP requests to the server, and template settings in the TeamCity Data Directory.</span>
              <span class="error" id="error_templateExternalId"></span>
            </td>
          </tr>
          <tr>
            <th><label for="description"><strong>Description:</strong></label></th>
            <td><forms:textField name="description" className="longField" maxlength="256" value=""/></td>
          </tr>
        </table>

        <div class="saveButtonsBlock">
          <forms:submit name="createTemplate" label="Create"/>
          <forms:cancel cameFromSupport="${cameFromSupport}"/>
          <forms:saving id="createProgress"/>
        </div>
        <c:if test="${fn:length(subProjects) == 0}">
          <input type="hidden" name="parentProjectId" id="parentProjectId" value="${project.externalId}"/>
        </c:if>

        <script type="text/javascript">
          BS.AdminActions.prepareTemplateIdGenerator("templateExternalId", "templateName", $('parentProjectId'));
        </script>
      </form>

      <script type="text/javascript">
        BS.CreateTemplateForm = OO.extend(BS.AbstractWebForm, {
          formElement: function () {
            return $('createTemplateForm');
          },

          savingIndicator: function () {
            return $('createProgress');
          },

          submit: function () {
            var that = this;
            BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
              createFailed: function (elem) {
                $('error_createTemplateFailed').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
              },

              invalidName: function (elem) {
                this.emptyName(elem);
              },

              emptyName: function (elem) {
                $('error_templateName').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
                that.highlightErrorField($("templateName"));
              },

              onParentProjectNotFoundError: function (elem) {
                $('error_parentProject').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
              },

              invalidId: function (elem) {
                $('error_templateExternalId').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
                that.highlightErrorField($("templateExternalId"));
              },

              emptyId: function (elem) {
                this.invalidId(elem);
              },

              duplicateId: function (elem) {
                this.invalidId(elem);
              },

              onCompleteSave: function (form, responseXML, err) {
                BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

                if (!err) {
                  BS.XMLResponse.processRedirect(responseXML);
                } else {
                  form.enable();
                }
              }
            }));
            return false;
          }
        });
      </script>
    </div>
  </jsp:attribute>
</bs:page>

